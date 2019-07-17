# sw_script

Hey Steve,

I put everything into a new directory called *'Final'*, it's pretty much the same as the old *'Testing'* directory, just with my changes.
You just need to put it into the same directoy as EEGlab and your inputs(`/nesi/nobackup/uoa00539`), and everything should work fine.

1. `cd ~
2. `git clone https://github.com/CallumWalley/sw_script.git`
3. `cp -r ~/sw_script/Final /nesi/nobackup/uoa00539`
4. `cd /nesi/nobackup/uoa00539/Testing`
5. Edit the submit.sh file.
  * Make sure `root_dir` is equal to `/nesi/nobackup/uoa00539`
  * Choose what operation you want.
  * Select the number of jobs you want to submit. (I reccomend keeping this smallish untill you can verify the results are correct)
  * Set downsample rate.
  * Set project code to `uoa00539`
  * If you want set `mail_address` and you will receive an email if any job is getting close to timing out. (Let me know)
6. `bash submit.sh`

Results will go into `./Outputs` slurm logs will go into `'/Logs`
