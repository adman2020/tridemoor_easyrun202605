$f = Get-ChildItem "D:\AI\StrideMoor\docs\*境界*"
Get-Content $f.FullName -Encoding UTF8
