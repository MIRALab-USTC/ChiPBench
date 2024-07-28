# ChiPBench

This repository contains the code for our manuscript *BENCHMARKING END-TO-END PERFORMANCE OF AI-BASED CHIP PLACEMENT ALGORITHMS*.

This project benchmarks placement algorithms based on [OpenROAD-flow-scripts](https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts).



## Dependencies

This project relies on the following dependencies:

- **OpenROAD**

  - Repository: [OpenROAD](https://github.com/The-OpenROAD-Project/OpenROAD)
  - Version: `v2.0-17198-g8396d0866`
  - Commit Hash: `8396d08669f418279c89b5bbd4d7e3f5204d3288`

- **Yosys**

  - Repository: [Yosys](https://github.com/YosysHQ/yosys)
  - Version: `Yosys 0.45+139`
  - Commit Hash: `4d581a97d6f0f3e545bcdaa9462b4276fab99fa3`




## Installation





### Install via Docker

```bash
docker pull tuzj/chipbench:v1.0
git clone https://github.com/ZhaojieTu/ChiPBench
cd ChiPBench
docker run -it -v $(pwd):/ChiPBench tuzj/chipbench:v1.0 bash
```





### Install via Pre-built Binaries  
For certain platforms, you can install OpenROAD and Yosys using pre-built binaries. Before proceeding with the installation, run the following setup script:

```bash
git clone https://github.com/ZhaojieTu/ChiPBench
cd ChiPBench
sudo ./setup/setup.sh
```

**OpenROAD**  

Pre-built binaries are available for the following platforms:  
- Ubuntu 20.04 / 22.04  
- Debian 11  

Download the release: [OpenROAD Release](https://github.com/Precision-Innovations/OpenROAD/releases/tag/2.0-17198-g8396d0866)  

Follow the official installation guide: [Installation Guide](https://openroad-flow-scripts.readthedocs.io/en/latest/user/BuildWithPrebuilt.html#install-openroad)  

**Yosys**  

Download the release: [Yosys Release](https://github.com/YosysHQ/oss-cad-suite-build/releases/tag/2024-11-22)  

Follow the official installation guide: [Installation Guide](https://github.com/YosysHQ/oss-cad-suite-build#installation)  






### Install from Source  

Building from source requires compiling the code, which can be time-consuming. If you prefer this method, please refer to the official documentation of each project:  

- [OpenROAD](https://github.com/The-OpenROAD-Project/OpenROAD/blob/master/docs/user/Build.md)
- [Yosys](https://github.com/YosysHQ/yosys?tab=readme-ov-file#building-from-source)

Note: Make sure to use the same commit as mentioned before.




## Dataset

The dataset used in this project is available at [Hugging Face](https://huggingface.co/datasets/MIRA-Lab/ChiPBench-D)

The statistics of our dataset:

| Id | Design           | \#Cells | \#Nets | \#Macros | \#Pins  | \#IOs |
|----|------------------|---------|--------|----------|---------|-------|
| 1  | ariane133        | 167907  | 197606 | 132      | 979135  | 495   |
| 2  | ariane136        | 171347  | 201428 | 136      | 1000876 | 495   |
| 3  | bp\_fe           | 33188   | 39512  | 11       | 185524  | 2511  |
| 4  | bp\_be           | 51382   | 62228  | 10       | 293276  | 3029  |
| 5  | bp               | 307055  | 348278 | 24       | 1642427 | 1198  |
| 6  | swerv\_wrapper   | 98039   | 113582 | 28       | 573688  | 1416  |
| 7  | bp\_multi        | 152287  | 174170 | 26       | 813050  | 1453  |
| 8  | vga\_lcd         | 127004  | 151946 | 62       | 706931  | 198   |
| 9  | dft68            | 41974   | 56217  | 68       | 226420  | 132   |
| 10 | or1200           | 26667   | 32740  | 36       | 153379  | 383   |
| 11 | mor1kx           | 68291   | 81398  | 78       | 394210  | 576   |
| 12 | ethernet         | 35172   | 44964  | 64       | 205739  | 211   |
| 13 | VeriGPU          | 71082   | 85081  | 12       | 421857  | 134   |
| 14 | isa\_npu         | 427003  | 548451 | 15       | 2406579 | 93    |
| 15 | ariane81         | 153873  | 180516 | 81       | 894420  | 495   |
| 16 | bp\_fe38         | 26859   | 32661  | 38       | 154162  | 2511  |
| 17 | bp\_be12         | 38393   | 47030  | 12       | 220938  | 3029  |
| 18 | bp68             | 164039  | 191475 | 68       | 887046  | 1198  |
| 19 | swerv\_wrapper43 | 95455   | 110902 | 43       | 560088  | 1416  |
| 20 | bp\_multi57      | 127553  | 146710 | 57       | 680748  | 1453  |




## Usage


### 1. Environment Setup

Before running any scripts, you need to set up the required environment variables. There are two methods to do this:

#### Option 1: Load Environment Variables Manually

Run the following command in your terminal:
```bash
source env.sh
```

#### Option 2: Set Environment Variables Permanently

Add the following lines to your `~/.bashrc` to avoid loading `env.sh` every time:
```bash
echo 'export OPENROAD_EXE=$(command -v openroad)' >> ~/.bashrc
echo 'export YOSYS_EXE=$(command -v yosys)' >> ~/.bashrc
source ~/.bashrc
```

---

### 2. Benchmarking

The  project supports two methods for running tests: using command line arguments or a JSON configuration file.

#### Method 1: Using Command Line Arguments


```bash
cd ChiPBench
python3 benchmarking/benchmarking.py --mode={mode} --config_setting={config_setting} --def_path={def_path} --evaluate_name={evaluate_name}
```


**Parameter Details**:
- `--mode`: Specifies the evaluation mode. Options include:
  - `macro`: Macro placement evaluation
  - `global`: Global placement evaluation
  - `mixsize`: Mixed-size placement evaluation
- `--config_setting`: Path to the specific design case's configuration file.
- `--def_path`: Input DEF file that describes the placement.
- `--evaluate_name`: The name of the evaluation. The output will be stored in `benchmarking_result/{evaluate_name}/metrics.json`.

**Example**:
```bash
python3 benchmarking/benchmarking.py --mode=macro --config_setting=flow/designs/nangate45/bp_multi_top/config.mk --def_path=../def/bp_multi_top_sa.def --evaluate_name=sa
```

The benchmarking results will be saved to:
```
benchmarking_result/sa/metrics.json
```


#### Method 2: Using a JSON Configuration File

You can also configure multiple test cases in a JSON file for batch execution.
```bash

python3 benchmarking/benchmarking.py --config_json={Config_Json}
```

**Example 1: Single Case Configuration**

Create a JSON file (e.g., `config_macro.json`) with the following content:
```json
{
    "evaluate_name": "example_global",
    "mode": "global",
    "config_setting": "flow/designs/nangate45/gcd/config.mk",
    "def_path": "flow/results/nangate45/gcd/base/3_3_place_gp.odb.def",
    "parallel": 1
}
```

**Example 2: Multiple Case Configuration**

When running multiple test cases simultaneously, configure the JSON file as follows:
```json
{
    "evaluate_name": "example_multi",
    "mode": "macro",
    "case_list": [
        {
            "config_setting": "path/to/config1.mk",
            "def_path": "path/to/def1.def"
        },
        {
            "config_setting": "path/to/config2.mk",
            "def_path": "path/to/def2.def"
        }
    ],
    "parallel": 2
}
```
The `parallel` parameter specifies the number of cases to run simultaneously, allowing you to fully utilize your system resources.








## Extra

The [extra](./extra/) directory contains scripts that may be useful. Detailed information can be found in the [README_extra](./extra/README.md).

- **pl2def.py**: Writes node coordinate information from `.pl` files in the Bookshelf format to `.def` files.
- **lefdef2bookshelf.py**: Converts LEF/DEF files to the Bookshelf format based on DREAMPlace.
