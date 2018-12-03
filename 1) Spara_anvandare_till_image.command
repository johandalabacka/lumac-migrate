#!/usr/bin/python
import os
import os.path
import platform
import re
import subprocess 
import sys

# Dirty hack to backport subprocess.check_output if python < 2.7
if "check_output" not in dir( subprocess ): # duck punch it in!
    def f(*popenargs, **kwargs):
        if 'stdout' in kwargs:
            raise ValueError('stdout argument not allowed, it will be overridden.')
        process = subprocess.Popen(stdout=subprocess.PIPE, *popenargs, **kwargs)
        output, unused_err = process.communicate()
        retcode = process.poll()
        if retcode:
            cmd = kwargs.get("args")
            if cmd is None:
                cmd = popenargs[0]
            raise CalledProcessError(retcode, cmd, output=output)
        return output
    subprocess.check_output = f

def select_from_dictionary(title, items):
	print "===", title, "==="
	names = items.keys()
	names.sort()
	for name in names:
		print name
	while True:
		print "enter selected>",
		s = raw_input().strip()
		if s == 'quit' or s == 'exit':
			return (None, None)
		if s in names:
			return (s, items[s])
		else:
			print "Invalid selection try again!"

def ask_string(message):
	print message
	while True:
		print ">",
		s = raw_input().strip()
		if s == 'quit' or s == 'exit':
			return ""
		elif s == "":
			print "Nothing entered, try again"
		else:
			return s

def ask_yes_or_no(message):
	print message
	while True:
		print ">",
		s = raw_input().strip().lower()
		if s in ['y', 'j', 'yes', 'ja']:
			return True
		elif s in ['n', 'no', 'nej']:
			return False
		else:
			print "Enter Y/J/Yes/Ja or N/No/Nej"
					
def get_freespace(p):
    """
    Returns the number of free bytes on the drive that ``p`` is on
    """
    s = os.statvfs(p)
    return s.f_frsize * s.f_bavail	

# If not started by root or sudo. Restart with sudo
if os.geteuid() != 0:
	result = subprocess.call(["sudo", sys.argv[0]])
	sys.exit(result)
	
removable_disk_path = os.path.dirname(sys.argv[0])



username = ask_string("Enter lucat-id of user")

if username == "":
	sys.exit(1)
	
	
home_dirs = {}
for item in os.listdir("/Users"):
	# ignore dot-files
	path = os.path.join("/Users", item)
	if not item.startswith(".") and os.path.isdir(path):
		home_dirs[item] = path

(userhome_name, userhome) = select_from_dictionary("Select home directory to make into image", home_dirs)	
if userhome == "":
	sys.exit(1)

macos_version = platform.mac_ver()[0]
if macos_version.startswith("10.4"):
	image_extension = ".sparseimage"
else:
	image_extension = ".sparsebundle"
	

image_path = os.path.join(removable_disk_path, username + image_extension)

# Ask if to reuse image
if os.path.exists(image_path):
	answer = ask_yes_or_no("Discimage already exists. Use it again?")
	if answer == False:
		# Loop and find xxx n.sparsebundle which doesn't exists
		n = 1
		finished = False
		while not finished:
			image_path = os.path.join(removable_disk_path, username + " " + str(n) + image_extension)
			if not os.path.exists(image_path):
				finished = True

# Create image
if not os.path.exists(image_path):	
	free_space_in_gb = get_freespace(removable_disk_path) / 1024 / 1024 / 1024
	if free_space_in_gb == 0:
		print "No free space on device"
	else:
		print "Creating disk image with size of %d GB at %s" % (free_space_in_gb, image_path)
	
	if macos_version.startswith("10.4"):
		# om os 10.4 sa funkar inte sparsebundle
		result = subprocess.call(["hdiutil", "create", "-size",  str(free_space_in_gb) + "g", "-fs", "Journaled HFS+",
			"-volname", username,image_path])
	else:		
		result = subprocess.call(["hdiutil", "create", "-size",  str(free_space_in_gb) + "g", "-fs", "Journaled HFS+",
			"-volname", username, "-type", "SPARSEBUNDLE", image_path])
	if result != 0:
		print "Error: Could not create image"
		sys.exit(1)

# Mount image
try:
	output = subprocess.check_output(['hdiutil', 'mount', image_path])
except subprocess.CalledProcessError:
	print "Error: Could not mount image ", image_path
	sys.exit(1)
	
m = re.search(r'(/Volumes/[^\n\r]+)', output)
if m == None:
	print "Error: mounting image:", output
	sys.exit(1)
	
mounted_path = m.group(1) # /Volumes/htz-tcr

# Rsync
# -r recursive
# -l copy symlinks as symlinks
# -p preserve permissions
# -t preserve times
# -E copy extended attributes, resource forks
# -v verbose output
# -8 filenames in 8-bit
# / on end of user_path so not synced into directory
result = subprocess.call(['rsync', '-rlptE8', userhome + "/", mounted_path])
if result != 0:
	print "Error: rsync failed"
	subprocess.call(['umount', mounted_path])
	sys.exit(1)

print "Successfully synced", userhome, "to", image_path
subprocess.call(['umount', mounted_path])

print "******** Finished *********"

