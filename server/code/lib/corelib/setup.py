from distutils.core import setup, Extension
from Cython.Build import cythonize
import os
from os import path

#cur_path = path.abspath(path.dirname(__file__))
#if path.exists(path.join(cur_path, '_corelib.so')):
#    os.remove('_corelib.c')
ext_modules = cythonize("*.pyx", exclude="numpy_*.pyx")
#if not ext_modules:
ext_modules = [
    Extension(
        '_corelib', ['_corelib.c', ],
        libraries=[ ], library_dirs=[],
    ) ]
setup(
  name = '_corelib',  ext_modules = ext_modules,
)
