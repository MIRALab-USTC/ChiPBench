openroad hash: `8396d08669f418279c89b5bbd4d7e3f5204d3288`

version: v2.0-17198-g8396d0866

https://github.com/Precision-Innovations/OpenROAD/releases/tag/2.0-17198-g8396d0866

yosys hash: `4d581a97d6f0f3e545bcdaa9462b4276fab99fa3`
https://github.com/YosysHQ/oss-cad-suite-build/releases/tag/2024-11-22

version: Yosys 0.45+139

docker run -it --net=host -v $(pwd):/ChiPBench chipbench:latest bash

docker run -it --rm --net=host -v $(pwd):/ChiPBench chipbench:latest bash

usage:
```bash
cd ChiPBench
python3 benchmarking/benchmarking.py  --mode={mode}  --config_setting={config_setting} --def_path={def_path} --evaluate_name={evaluate_name}
```
mode:
- macro
- global
- mixsize

example:
```bash
python3 benchmarking/benchmarking.py  --mode=macro  --config_setting=flow/designs/nangate45/bp_multi_top/config.mk --def_path=../def/bp_multi_top_sa.def --evaluate_name=sa
```

output:
`benchmarking/sa/metrics.json`

