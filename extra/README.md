# Extra Scripts

This directory contains additional scripts that might be useful.

- **pl2def.py**: Writes node coordinate information from `.pl` files in the Bookshelf format to `.def` files.
- **lefdef2bookshelf.py**: Converts LEF/DEF files to the Bookshelf format based on DREAMPlace.

## Details

### **pl2def.py**

If your placement is done using the Bookshelf format, you can use this script to transfer node coordinate information from a `.pl` file to a `.def` file.

Usage:
```bash
python pl2def.py --pl="example.pl" --inputdef="input.def" --outputdef="output.def"
```
- `pl`: Path to the input `.pl` file.
- `inputdef`: Path to the input `.def` file.
- `outputdef`: Path to the output `.def` file.

### **lefdef2bookshelf.py**

> Note: The node names in the converted Bookshelf files will be the same as those in the DEF files. This might result in illegal characters causing DREAMPlace or other programs to fail when parsing the Bookshelf files.

If you need to use the Bookshelf format for placement algorithms, you can use this script for conversion.

This script is based on DREAMPlace, so you need to install [DREAMPlace](https://github.com/limbo018/DREAMPlace) first.

Place this script in the `dreamplace/` directory of DREAMPlace.

Usage:
- Configure the DREAMPlace JSON configuration file: Set `def_input`, `lef_input`, `lib_input`, and `verilog_input` to the corresponding file paths.
- Run the script with the command:
```bash
python dreamplace/lefdef2bookshelf.py case1.json
```
- The generated Bookshelf format files will be located in the `benchmarks/` directory. For example, you will find the Bookshelf files in `benchmarks/case1` (the subdirectory name corresponds to the JSON file name).