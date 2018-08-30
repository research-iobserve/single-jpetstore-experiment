# single-jpetstore-clustering
Experiment setup with a single service jpetstore to evaluate user behavior.

## Scripts, configuration files and their purpose
* `compare-behavior.sh` compare and compile results of different behaviors with te evaluate behavior tool
* `config.template` template of the experiment configuration
* `execute-all-fuzzy.sh` run all observation tasks with randomized behaviors (executes execute-observation.sh)
* `execute-analysis-ssp.sh` (outdated) analysis for the SSP paper 2017
* `execute-analysis.sh` run application and analysis, uses docker-compose
* `execute-kieker-analysis.sh` use observed data and analyze it with Kieker
* `execute-observation.sh` up to date JPetStore experiment execution, generates user data
* `execute-session-reconstruction.sh` tool to fix collected data and add missing session data
* `reconstructor.config` example reconstruction configuration

## Configuration

All scripts share a common configuration file `config`. 

* `DATA_DIR` directory for the monitoring data. A running collector will store all events in the specified directory or a sub-directory thereof.
* `COLLECTOR` refers to the executable script of an collector service of the https://github.com/research-iobserve/iobserve-analysis project
* `WORKLOAD_RUNNER` refers to our selenium based workload driver for the JPetStore which can be found in https://github.com/research-iobserve/selenium-workloads
* `PHANTOM_JS` phantomJs driver for selenium

## Execute-Observation

`execute-observation.sh` takes two parameters. The first is a workload specification file and the second an experiment id. If no workload is specified, the script runs without workload driver and the JPetStore can be run interactively. In case a workload is specified, it is also necessary to specify the experiment id. The script assumes the use of phantomJs. However, the workload runner works better with the Chrome driver. If you want to switch, please adjust the script.

