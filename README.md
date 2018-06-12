# single-jpetstore-clustering
Experiment setup with a single service jpetstore to evaluate user behavior.

## Scripts, configuration files and their purpose
* compare-behavior.sh compare and compile results of different behaviors with te evaluate behavior tool
* config.template template of the experiment configuration
* execute-all-fuzzy.sh run all observation tasks with randomized behaviors (executes execute-observation.sh)
* execute-analysis-ssp.sh (outdated) analysis for the SSP paper 2017
* execute-analysis.sh run application and analysis, uses docker-compose
* execute-kieker-analysis.sh use observed data and analyze it with Kieker
* execute-observation.sh up to date JPetStore experiment execution, generates user data
* execute-session-reconstruction.sh tool to fix collected data and add missing session data
* reconstructor.config example reconstruction configuration
