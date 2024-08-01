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

The dataset used in this project is available at [Google Drive](https://drive.google.com/drive/folders/1aNOt25yFUYK9lj-LhoaWaVbsT_vmJPQ1?usp=sharing).



## Usage

### Benchmarking

To run the benchmarking, follow these steps:

1. Prepare the DEF files that have undergone placement for benchmarking.
2. Configure the JSON file as described in the [Configuration](#configuration) section.
3. Run the benchmarking script:
   ```bash
    source ./env.sh
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
