Cedar and Cedar schema highlight queries are copied from
[SwornSystems/tree-sitter-cedar](https://github.com/SwornSystems/tree-sitter-cedar)
at revision `2e9f10824728b13d4c019774b32ca0a883e97f96` (2026-08-30).
The schema queries live in `../cedarschema/highlights.scm`.

Keep both query files and the parser revision in `lua/plugins/treesitter.lua`
in sync when updating. The classic nvim-treesitter installer installs the
parsers but does not install queries from custom grammar repositories.

Upstream's MIT license follows:

Permission is hereby granted, free of charge, to any
person obtaining a copy of this software and associated
documentation files (the "Software"), to deal in the
Software without restriction, including without
limitation the rights to use, copy, modify, merge,
publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software
is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice
shall be included in all copies or substantial portions
of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF
ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT
SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
