# An InDesign Markup Language Validator

XProc-Step for IDML validation. See schema directory for supported versions.

## Create an RelaxNG schema from InDesign

1. Create an InDesign Script containing the code below. Executing the script
will create RNC schema files in the directory `/idml-schema/package` or `C:/idml-schema/package` 
depending on your operating system.

```js
app.generateIDMLSchema(Folder("/idml-schema/package"), true);
```

2. Copy the files to this repository in `schema/rnc/{$version}`, 
whereas `{$version}` is the version number of InDesign.

3. Run `rnc/rnc2rng.sh {$version}` to create
 the RNG schema files in the directory `rng/{$version}`