#!/usr/bin/env python
# encoding: utf-8

import click
import jinja2
import os
import pipes
import re
import shutil
import yaml


def shellescape(iterable):
    return ' '.join(pipes.quote(arg) for arg in iterable)


@click.command()
@click.option('--config', type=click.File('rb'), default='config.yaml', show_default=True)
@click.option('--build-variant', default='release', show_default=True)
@click.option('--template-dir', type=click.Path(exists=True, file_okay=False), required=True)
@click.option('--output-dir', '-o', type=click.Path(exists=False, file_okay=False), required=True)
def main(config, build_variant, template_dir, output_dir):
    loader_paths = [os.path.dirname(os.path.abspath(template_dir))]

    jinja_env = jinja2.Environment(
        keep_trailing_newline=True,  # newline-terminate generated files
        lstrip_blocks=True,  # so can indent control flow tags
        trim_blocks=True,  # so don't need {%- -%} everywhere
        undefined=jinja2.StrictUndefined)
    jinja_env.filters.update({
        'shellescape': shellescape,
    })

    doc = yaml.load(config)
    try:
        variant_flags = doc['build_variants'][build_variant]
    except KeyError:
        click.echo('FATAL: %r is not in config file.' % build_variant)
        os.exit(1)

    context = {
        'CC': doc['CC'],
        'CXX': doc['CXX'],
        'CFLAGS': doc['CFLAGS'] + variant_flags,
        'CXXFLAGS': doc['CXXFLAGS'] + variant_flags,
        'LDFLAGS': doc['LDFLAGS'] + variant_flags,
    }

    shutil.copytree(template_dir, output_dir)
    for dirpath, dirnames, filenames in os.walk(output_dir):
        for filename in filenames:
            abs_filename = os.path.join(dirpath, filename)
            new_name, n = re.subn(r'\.jinja$', '', abs_filename)
            if not n:
                continue

            with open(abs_filename, 'rb') as f:
                contents = f.read()

            rendered_content = jinja_env.from_string(contents).render(context)
            with open(new_name, 'wb') as f:
                f.write(rendered_content)

            os.unlink(abs_filename)


if __name__ == '__main__':
    main()

