# openbsd-integrity
integrity is simple script for checking system integrity and generating integrity hash files using [mtree](https://man.openbsd.org/mtree.8)

## Usage
* Before starting, set seed value to KEY variable. This can be ~20 digit number.

### Generating hash files
```
./integrity gen <path to directory>
```
sample command:
```
./integrity gen /int_sam
```
* This will generate hash files `hash_bin`, `hash_sbin`, `hash_usr` in `/int_sam` directory. This hash files will contain hash of all files contained in `/bin`,`/sbin` and `/usr`.
* If integrity is started with gen parameter with folder that already contains `hash_bin`, `hash_sbin`, `hash_usr`. Those files will be moved to folder named `old_hash`.
* After every process of generating hash files, integrity will log status activity to /var/log/messages
```
Dec 11 13:22:14 SampleMachine [Integrity]: Generating new integrity hash files... Hash files location: /int_sam/. hash functions: cksum,md5digest,sha1digest,sha256digest
Dec 11 13:26:01 SampleMachine [Integrity]: Generating new integrity hash files completed!

```
* _More folders will be added later, or more specifically option to add more folders._


### Verifying files
```
./integrity ver <path to directory>
```
sample command:
```
./integrity ver /int_sam
```
* If folder contains hash files `hash_bin`, `hash_sbin`, `hash_usr`, integrity will check the integrity of all files contained in `/bin`,`/sbin` and `/usr`, and will report changes and status to root with mail.
* Same as `gen` argument, `var` file will log activity /var/log/messages

### On boot verification - broken
* **integrity.sh needs to be in / (root dir) for installation to work**
* Integrity can be started on boot, and verify all files and changes in specified folders.
 ```
./integrity install <path to directory>
```
sample command:
```
./integrity install /int_sam
```
* This will add `./integrity ver /int_sam` to `rc.local` file, which will run verification on every boot