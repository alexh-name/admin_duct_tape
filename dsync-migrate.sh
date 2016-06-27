#!/bin/sh
 
# The address is read from $1.
# The list of user-password pairs is read from ./upw-lists/${address}/remote.txt
# If the directory doesn't exist, it will be created at first run.
 
set -eu
 
create_new_pairs="1"
address="$1"
 
user_pw_list_dir="./upw-lists/${address}"
remote_user_pw_list_file="${user_pw_list_dir}/remote.txt"
 
date_unix_time="$(date +%Y%m%d-%s)"
new_user_pw_list_file="${user_pw_list_dir}/new_${date_unix_time}.txt"
 
function checkcontent() {
  awk -v FS=' ' 'NR=="'$line'"{print $"'$field'";}' ${remote_user_pw_list_file}
}
 
function get_pairs() {
  field="1"
  local_user="$(checkcontent)"
  remote_imap_user="${local_user}@${address}"
  field="2"
  remote_imap_passwd="$(checkcontent)"
  passwd="${remote_imap_passwd}"
}
 
function check_existence() {
  if id "${local_user}" >/dev/null 2>&1; then
    user_exists="1"
  else
    user_exists="0"
  fi
}
 
function create_new_pairs() {
  printf '%s' "${local_user}" >> ${new_user_pw_list_file}
  if [[ "${user_exists}" -eq "0" ]]; then
    passwd="$(</dev/urandom tr -dc A-Za-z0-9 | head -c20)"
  else
    passwd='USER_EXISTED'
  fi
  printf ' %s\n' "${passwd}" >> ${new_user_pw_list_file}
}
 
function create_user() {
  new_user="${local_user}"
  new_passwd="${passwd}"
 
  useradd ${new_user}
  echo "${new_user}:${new_passwd}" | chpasswd
}
 
function sync() {
  if [[ "${user_exists}" -eq "0" ]]; then
    mv -f /home/${local_user}/Maildir \
     /home/${local_user}/Maildir.dsyncb-${date_unix_time}
    su - ${local_user} -c "doveadm -o mail_fsync=never \
     -o imapc_user=${remote_imap_user} \
     -o imapc_password=${remote_imap_passwd} backup -R -u ${local_user} imapc:"
  else
    su - ${local_user} -c "doveadm -o mail_fsync=never \
     -o imapc_user=${remote_imap_user} \
     -o imapc_password=${remote_imap_passwd} sync -1 -R -u ${local_user} imapc:"
  fi

}
 
if [ ! -d "${user_pw_list_dir}" ]; then
  mkdir -pv "${user_pw_list_dir}"
  echo "Now put the remote user-password list to ${user_pw_list_dir}/remote.txt".
  exit 1
fi
line="1"
line_count="$(wc -l ${remote_user_pw_list_file} | cut -d ' ' -f 1)"
until [[ "${line}" -gt "${line_count}" ]]; do
  get_pairs
  check_existence
  if [[ "${create_new_pairs}" -eq "1" ]]; then
    create_new_pairs
  fi
  if [[ "${user_exists}" -eq "0" ]]; then
    create_user
  fi
  sync
  line=$(( ${line} + 1 ))
done
