# This file is part of Relax and Recover, licensed under the GNU General
# Public License. Refer to the included LICENSE for full text of license.
#
# Restore from remote backup via DUPLICIY over rsync

if [ "$BACKUP_PROG" = "duplicity" ]; then

    LogPrint "========================================================================"
    LogPrint "Restoring backup with $BACKUP_PROG from $DUPLICITY_HOST/$DUPLICITY_PATH/$(hostname)"
    LogPrint "========================================================================"
    
    read -p "ENTER for start restore: " 2>&1
    
    export TMPDIR=/mnt/local
    
    export PYTHONHOME=/usr/lib64/python2.6
    export PYTHONPATH=/usr/lib64/python2.6:/usr/lib64/python2.6/lib-dynload:/usr/lib64/python2.6/site-packages:/usr/lib64/python2.6/site-packages/duplicity
    export PASSPHRASE="$BACKUP_DUPLICITY_GPG_ENC_PASSPHRASE"
    export HOSTNAME=$(hostname)
    
    GPG_OPT="$BACKUP_DUPLICITY_GPG_OPTIONS"
    GPG_KEY="$BACKUP_DUPLICITY_GPG_ENC_KEY"
    PASSPHRASE="$BACKUP_DUPLICITY_GPG_ENC_PASSPHRASE"
    
    # Setting the pass phrase to decrypt the backup files
    export PASSPHRASE
    
    starttime=$SECONDS

    # ensure we have enougth space to unpack the backups (they are 100M, but neet up to 1G to unpack!)
    mkdir -p /mnt/tmp
    mount -t tmpfs none /mnt/tmp
    
    LogPrint "with CMD: $DUPLICITY_PROG -v 5 $GPG_OPT --encrypt-key $GPG_KEY --force $BACKUP_DUPLICITY_URL/$HOSTNAME/ /mnt/local/"
    LogPrint "Logging to $TMP_DIR/duplicity-restore.log"
    $DUPLICITY_PROG -v 5 $GPG_OPT --encrypt-key $GPG_KEY --force --tempdir=/mnt/tmp $BACKUP_DUPLICITY_URL/$HOSTNAME/ /mnt/local | tee $TMP_DIR/duplicity-restore.log
    _rc=$?
    
    transfertime="$((SECONDS-$starttime))"
    sleep 1
    
    #LogPrint "starttime = $starttime"
    #ogPrint "transfertime = $transfertime"
    
    LogPrint "========================================================================"
    
    
    if [ "$_rc" -gt 0 ]; then
        LogPrint "WARNING !
    There was an error while restoring the archive.
    Please check '$LOGFILE' and $TMP_DIR/duplicity-restore.log for more information. 
    You should also manually check the restored system to see wether it is complete.
    "
    
        _message="$(tail -14 ${TMP_DIR}/duplicity-restore.log)"
    
        LogPrint "Last 14 Lines of ${TMP_DIR}/duplicity-restore.log:"
        LogPrint "$_message"
    fi
    
    if [ $_rc -eq 0 ] ; then
            LogPrint "Restore comleted in $transfertime seconds."
    fi
    
    LogPrint "========================================================================"
    
    # Save the logfile to the recoverd filesystem for further checking
    LogPrint "Transfering Logfile $TMP_DIR/duplicity-restore.log to /mnt/local/tmp/"
    cp -v $TMP_DIR/duplicity-restore.log /mnt/local/tmp/
fi

