# Migrate users

This is a couple of scripts I made for the lumac-project at Lund university to transfer local accounts from computers to new accounts in the managed solution. They are ment to be used together with a removable harddisk. The extension .command makes the double-clickable in finder. The scripts must be on the removable disk because they save and restore to the same folder as they are located in.

## 1) Spara_anvandare_till_image.command

This script is used to save an account to a re


1. The script wants your sudo password

```
    Password: ******
```
2. This script asks for the lucat-id (which is the name of the domain account at LU) which the users home directory will be transfered to

    ```
    Enter lucat-id of user
    > ni8854pa
    ```

3. You will be presented with all folders in /Users and should write which one you want to have transfered to the removable disk

```
=== Select home directory to make into image ===
Shared
nisse
roger
enter selected> nisse
```
4. It will then create a diskimage in the same folder as the script. It will be named after the lucat-id you wrote above and .sparsebundle. For example ni8854pa.sparsebundle

## 2) Aterstall_anvandare.command

This script is used to restore the diskimage as an account on a mac

1. The script wants your sudo password

```
    Password: ******
```

2. It will then show all diskimages in the same folder as the script and you should write which one to restore 

```
 === select diskimage: ===
ni8854pa
enter selected>
```

3. Restore is done to /Users/xxx where xxx is the diskimage you selected

