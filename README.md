# ChiPBench

This repository contains the code for our manuscript *BENCHMARKING END-TO-END PERFORMANCE OF AI-BASED CHIP PLACEMENT ALGORITHMS*.

This project benchmarks placement algorithms based on [OpenROAD-flow-scripts](https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts).

## Dependencies

- [OpenROAD-flow-scripts](https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts)
- Python is used for scripting purposes. Most dependencies are built-in Python libraries, but additional required packages are listed in the `requirements.txt` file.

## Installation

```bash
git clone --recursive https://github.com/ZhaojieTu/ChiPBench
cd ChiPBench
pip install -r requirements.txt
```


### OpenROAD-flow-scripts Installation

We utilize the OpenROAD-flow-scripts provided by The-OpenROAD-Project. The installation process is detailed in the [README_OpenROAD](https://github.com/ZhaojieTu/OpenROAD-flow-scripts/blob/master/README.md) or the [official repository](https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts).



## Dataset

The dataset used in this project is available at [Hugging Face](https://huggingface.co/datasets/ZhaojieTu/ChiPBench-D)

The statistics of our dataset:

| Id | Design         | \#Cells | \#Nets  | \#Macros | \#Pins  | \#IOs | \#Edges |
|----|----------------|---------|---------|----------|---------|-------|---------|
| 1  | 8051           | 13865   | 16424   | 0        | 50848   | 10    | 16174   |
| 2  | ariane136      | 175248  | 191081  | 136      | 609834  | 495   | 187911  |
| 3  | ariane133      | 168551  | 184856  | 132      | 592261  | 495   | 183142  |
| 4  | bp             | 301030  | 333364  | 24       | 984093  | 1198  | 333364  |
| 5  | bp\_be         | 50881   | 58428   | 10       | 182949  | 3029  | 58092   |
| 6  | bp\_fe         | 33206   | 36379   | 11       | 111510  | 2511  | 36203   |
| 7  | CAN-Bus        | 815     | 935     | 0        | 2637    | 13    | 935     |
| 8  | DE2\_CCD\_edge | 2333    | 3270    | 0        | 7823    | 64    | 3170    |
| 9  | dft48          | 48488   | 52575   | 68       | 125501  | 132   | 50654   |
| 10 | FPGA-CAN       | 140848  | 178913  | 0        | 532024  | 4     | 176472  |
| 11 | iot shield     | 904     | 1006    | 0        | 2995    | 33    | 974     |
| 12 | mor1kx         | 104293  | 130743  | 0        | 374983  | 576   | 125979  |
| 13 | or1200         | 43386   | 32195   | 20       | 97047   | 383   | 31958   |
| 14 | OV7670\_i2c    | 332     | 340     | 0        | 979     | 29    | 316     |
| 15 | picorv         | 8851    | 10531   | 0        | 32195   | 409   | 10470   |
| 16 | serv           | 1291    | 1482    | 0        | 3915    | 306   | 1403    |
| 17 | sha256         | 10120   | 12283   | 0        | 38758   | 77    | 12176   |
| 18 | subrisc        | 859382  | 1103295 | 0        | 3359066 | 34    | 1092653 |
| 19 | swerv\_wrapper | 96435   | 105026  | 28       | 354652  | 1416  | 104565  |
| 20 | toygpu         | 368081  | 466513  | 0        | 1399167 | 11    | 461675  |

## Usage

### Benchmarking

To run the benchmarking, follow these steps:

1. Prepare the DEF files that have undergone placement for benchmarking.
2. Configure the JSON file as described in the [Configuration](#configuration) section.
3. Run the benchmarking script:
   ```bash
    source ./OpenROAD-flow-scripts/env.sh
    python benchmarking/benchmarking.py config.json
   ```

### Configuration

Example: `config_macro.json`:
```json
{
    "evaluate_name":"method_name",
    "mode":"macro",
    "case":
    {
        "ariane133":"ariane133.def",
        "ariane136":"ariane136.def",
        "bp":"black_parrot.def",
        "bp_fe":"bp_fe.def",
        "bp_be":"bp_be.def",
        "dft48":"dft48.def",
        "swerv_wrapper":"swerv_wrapper.def",
        "or1200":"or1200.def"
    },
    "parallel":3
}
```

| JSON Parameter  | Description                                     | Values                                                 |
|-----------------|-------------------------------------------------|--------------------------------------------------------|
| evaluate_name   | The name of the evaluation                      | string                                                 |
| mode            | Specifies if the evaluation is for macro placement or global placement | `macro_place: "macro" or 1`, `global_place: "global" or 2` |
| case            | Specifies the DEF files for each case to be evaluated; partial evaluation is also allowed | `"case": "case_place.def"`                             |
| parallel        | Number of cases to run in parallel              | int                                                    |

### Benchmarking Results

The benchmarking results will be saved in the "benchmarking_result" folder.

The results are organized in the following format:
```bash
benchmarking_result
├── method_name
│   ├── logs
│   ├── reports
│   ├── results
│   ├── average_result.json
│   ├── metrics.json
│   ├── normalized_metrics.json
```

- `logs`: OpenROAD log files for each case
- `reports`: OpenROAD report files for each case
- `results`: OpenROAD result files for each case
- `metrics.json`: Raw metrics for each case
- `normalized_metrics.json`: Normalized metrics for each case 
  - Normalization is based on baseline values: `normalized_metric = metric/baseline`
- `average_result.json`: Average normalized metrics for each case


## Extra

The [extra](./extra/) directory contains scripts that may be useful. Detailed information can be found in the [README_extra](./extra/README.md).

- **pl2def.py**: Writes node coordinate information from `.pl` files in the Bookshelf format to `.def` files.
- **lefdef2bookshelf.py**: Converts LEF/DEF files to the Bookshelf format based on DREAMPlace.