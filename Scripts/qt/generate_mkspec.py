#!/usr/bin/env python
# encoding: utf-8

import click
import jinja2
import os
import pipes
import re
import shutil
import yaml
import sys
import shlex


def shellescape(iterable):
    return ' '.join(pipes.quote(arg) for arg in iterable)


@click.command()
@click.option('--config', type=click.File('rb'), default='config.yaml', show_default=True)
@click.option('--build-variant', default='release', show_default=True)
@click.option('--extra-var', '-v', 'extra_vars', metavar='extra_vars', multiple=True, type=(str, str,))
@click.option('--template-dir', type=click.Path(exists=True, file_okay=False), required=True)
@click.option('--output-dir', '-o', type=click.Path(exists=False, file_okay=False), required=True)
def main(config, build_variant, extra_vars, template_dir, output_dir):
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
        sys.exit(1)

    user_vars = dict(
        (k.encode('utf8'), shlex.split(v.encode('utf8')))
        for k, v in extra_vars)

    def seq(name, prefix):
        return (name, prefix + user_vars.get(name, []))

    def atom(name, default_value):
        return (name, user_vars.get(name, [None])[0] or default_value)

    context = dict(user_vars)
    context.update([
        atom('CC', doc['CC']),
        atom('CXX', doc['CXX']),
        seq('CFLAGS', doc['CFLAGS'] + variant_flags),
        seq('CXXFLAGS', doc['CXXFLAGS'] + variant_flags),
        seq('LDFLAGS', doc['LDFLAGS'] + variant_flags),
    ])

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
    main.main()
