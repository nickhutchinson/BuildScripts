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
from collections import namedtuple


def shellescape(iterable):
    return ' '.join(pipes.quote(arg) for arg in iterable)


JINJA_CONFIG = dict(
    keep_trailing_newline=True,  # newline-terminate generated files
    lstrip_blocks=True,  # so can indent control flow tags
    trim_blocks=True,  # so don't need {%- -%} everywhere
    undefined=jinja2.StrictUndefined)


@click.command()
@click.option('--config', type=click.File('rb'), default='config.yaml', show_default=True)
@click.option('--build-variant', default='release', show_default=True)
@click.option('--extra-var', '-v', 'extra_vars', metavar='extra_vars', multiple=True, type=(str, str, ))
@click.option('--template', type=click.Path(exists=True, resolve_path=True), required=True)
@click.option('--output', '-o', type=click.Path(exists=False, resolve_path=True), required=True)
def main(config, build_variant, extra_vars, template, output):
    jinja_env = jinja2.Environment(**JINJA_CONFIG)
    jinja_env.filters.update(shellescape=shellescape)

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

    class Inst(object):
        CopyTree = namedtuple('CopyTree', 'src dest')
        RenderTemplate = namedtuple('RenderTemplate', 'src dest')
        Unlink = namedtuple('Unlink', 'file')

    program = []

    if os.path.isdir(template):
        program.append(Inst.CopyTree(template, output))
        for dirpath, dirnames, filenames in os.walk(template):
            for filename in filenames:
                rel_path = os.path.relpath(os.path.join(dirpath, filename),
                                           template)
                abs_filename = os.path.normpath(os.path.join(output, rel_path))
                new_name, n = re.subn(r'\.jinja$', '', abs_filename)
                if n:
                    program.append(Inst.RenderTemplate(abs_filename, new_name))
                    program.append(Inst.Unlink(abs_filename))
    else:
        program.append(Inst.RenderTemplate(template, output))

    for inst in program:
        if isinstance(inst, Inst.CopyTree):
            shutil.copytree(inst.src, inst.dest)

        elif isinstance(inst, Inst.RenderTemplate):
            with open(inst.src, 'rb') as f:
                contents = f.read()
            rendered_content = jinja_env.from_string(contents).render(context)
            with open(inst.dest, 'wb') as f:
                f.write(rendered_content)

        elif isinstance(inst, Inst.Unlink):
            os.unlink(inst.file)

        else:
            assert False


if __name__ == '__main__':
    main.main()
