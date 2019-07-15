#!/bin/bash
#===========================================================#
#                         Variables                         #
#===========================================================#
root_output_dir="/nesi/nobackup/nesi99999/uoa00539/OutputFiles/"  #Where outputs go
root_input_dir="/nesi/nobackup/nesi99999/uoa00539/"  #Where outputs go

operation="RS" 
# can be any one of.... 
          #RS_BCST_RMET_Processed
          #RS_Processed
          #RS_BCST_RMET
          #RS

debug="true"        # Set to "false"
wait_time="0"       # Time between each job submission. Only neccicary if you want to read the outputs.
num_jobs=4         # Max number of slurm jobs to submit in one go.

#===========================================================#
#           No need to change anything below here           #
#===========================================================#
ls root_output_dir > /dev/null

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
    echo "No operation given. Must be one of ....\nRS_BCST_RMET_Processed\nRS_Processed\nRS_BCST_RMET\nRS\n"
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
        output_path=${root_output_dir}linux_$(date +%Y%m%d)_${filename}_${operation}.xslx
        
        if [ ! -f "${output_path}" ]; then 

            echo "Using input '${line}'...\n" 
            echo "Operation will write to path '$output_path'"
            touch ${output_path}           
            num_jobs=$((${num_jobs} - 1))

            if [ ${debug} != "false" ]; then
                echo "Submitting job"
                sleep ${wait_time}
                #sbatch -A <project_code> -t 10 -p NeSI --wrap  "echo hello world"
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


