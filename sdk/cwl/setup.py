# Copyright (C) The Arvados Authors. All rights reserved.
#
# SPDX-License-Identifier: Apache-2.0

import setuptools
import runpy

from pathlib import Path

arvados_version = runpy.run_path(Path(__file__).with_name('arvados_version.py'))
arv_mod = arvados_version['ARVADOS_PYTHON_MODULES']['arvados-cwl-runner']
version = arv_mod.get_version()
setuptools.setup(
    cmdclass=arvados_version['CMDCLASS'],
    install_requires=[
        *arv_mod.iter_dependencies(version=version),
        'cwltool == 3.3.20261106131234',
        'schema-salad == 8.10.20261106141337',
        'ciso8601 >= 2.0.0',
        'packaging',
    ],
    version=version,
)
