#!/bin/bash
#===========================================================#
#                         Variables                         #
#===========================================================#
root_dir="/nesi/nobackup/uoa00539/"
operation="RS" 
# can be any one of.... 
          #RS_BCST_RMET_Processed
          #RS_Processed
          #RS_BCST_RMET
          #RS

wait_time="0"       # Time between each job submission. Only neccicary if you want to read the outputs.
num_jobs="5"       # Number of jobs this script will submit.
downsample_rate="1"
project_code="uoa00539"
#===========================================================#
#           No need to change anything below here           #
#===========================================================#

cpus=8
root_output_dir="${root_dir}OutputFiles/"    #Where outputs go
root_input_dir="${root_dir}"                 #Where inputs go
working_dir="${root_dir}Testing/"
log_dir="${root_dir}Log/"				# SLURM outputs

#Validate directories

mkdir -pv ${root_dir} ${root_output_dir} ${root_input_dir} ${working_dir} ${log_dir} 

debug="false"        # Set to "false"
interactive="false"        # If true will not use slurm.

prefix="STEP_1_Processing_" #All scripts start with this.
suffix="_v3.m"              #All scripts end with this.

script_name=${prefix}${operation}${suffix}

#set variables based on operation type

case ${operation} in
"RS_BCST_RMET_Processed")
    input_list=$(ls ${root_input_dir}AllRAWfiles4Preprocess/ParticipantsProcessed/**/*p_*.mat)
;;
"RS_Processed")
    input_list=$(ls ${root_input_dir}AllRAWfiles4Preprocess/ParticipantsProcessed/**/*p_*3rs.mat)
;;
"RS_BCST_RMET")
    input_list=$(ls ${root_input_dir}AllRAWfiles/Participants/*.RAW)
;;
"RS")
    input_list=$(ls ${root_input_dir}AllRAWfiles/Participants/*3rs.RAW)
;;
*)
    echo "No operation given. Must be one of ....\nRS_BCST_RMET_Processed\nRS_Processed\nRS_BCST_RMET\nRS"
;;
esac

if [ ${debug} != "false" ]; then
    echo "NOTE: This is a debug run, no slurm jobs will be submitted. To fix this change 'debug=false'"
fi

echo "Submitting ${num_jobs} jobs using ${script_name} ..."

for line in ${input_list[@]}; do 
    
    if [ ! ${num_jobs} -lt 1 ]; then
        input_path=${line}
        filename=$(basename $line)
        filename="${filename%.*}"
        job_name="${operation}_${filename}"
        output_path="${root_output_dir}linux_$(date +%Y%m%d)_${filename}_${operation}.xlsx"
        
        if [ ! -f "${output_path}" ]; then 

            echo "Using input '${line}'..." 
            echo "Operation will write to path '$output_path'"
            touch ${output_path}           
            num_jobs=$((${num_jobs} - 1))
            cd ${working_dir}
        
            if [ ${debug} != "true" ]; then        
                bash_file="${log_dir}.${operation}_${filename}"
cat <<mainEOF > ${bash_file}
#!/bin/bash -e

#=================================================#
#SBATCH --time                      10:00:00
#SBATCH --account                   ${project_code}
#SBATCH --job-name                  ${job_name}
#SBATCH --output                    %x.output
#SBATCH --cpus-per-task             ${cpus}
#SBATCH --mem                       20GB
#SBATCH --output                    ${log_dir}%x
#=================================================#
# Avoid possible future version issues
module load MATLAB/2018b

module load MATLAB
matlab -nojvm -r "downsampleRate=${downsample_rate}; \\
input_path='${input_path}'; \\
filename='${filename}'; \\
output_path='${output_path}'; \\
script_name='${script_name}'; \\
launch; exit;"
mainEOF

                if [ ${interactive} != "true" ]; then
                    echo "Submitting job"
                    sbatch ${bash_file}
                    sleep ${wait_time}                   
                else
                    echo "Running job interactively"
                    bash ${bash_file}
                    sleep ${wait_time}               
                fi 
                
            else    
                echo "Pretend Submitting job"
            fi

        else

            echo "File '$output_path' already exists. Skipping....."

        fi
    else
        echo "Specified number of jobs submitted."
        exit 0
    fi
    
done

echo "No new input-files left!!!"
exit 0


