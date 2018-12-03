#!/usr/bin/python
import os
import os.path
import re
import sys
import subprocess

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

def get_userid(username):
	try:
		output = subprocess.check_output(['id', '-u', username])
		userid = int(output)
		return userid
	except subprocess.CalledProcessError:
		return -1

	
		

black_list = ['ccc-3.4.5.dmg']
disk_image_exts = ['.dmg', '.sparseimage', '.sparsebundle']

# If not started by root or sudo. Restart with sudo
if os.geteuid() != 0:
	result = subprocess.call(["sudo", sys.argv[0]])
	sys.exit(result)
	
# Find all disc-images on disk
removable_disk_path = os.path.dirname(sys.argv[0])
disk_images = {}
for item in os.listdir(removable_disk_path):
	(name, ext) = os.path.splitext(item)
	# ignore dot-files, blacklisted and only allowed extensions
	if not name.startswith(".") and not item in black_list and ext in disk_image_exts:
		disk_images[name] = os.path.join(removable_disk_path, item)

(disk_image_name, disk_image) = select_from_dictionary("select diskimage:", disk_images)
if disk_image == None:
	print "quitting....."
	sys.exit(0)

m = re.match(r'^(\S+).*', disk_image_name)
username = m.group(0)
userid = get_userid(username)
userhome = os.path.join("/", "Users", username)
if  userid == -1:
	print "Error: no user", username, "found on system"
else:
	print "User", username, "(", userid, ") will be read from image"



try:
	output = subprocess.check_output(['hdiutil', 'mount', disk_image])
except subprocess.CalledProcessError:
	print "Could not mount image ", disk_image
	sys.exit(1)
	
m = re.search(r'(/Volumes/[^\n\r]+)', output)
if m == None:
	print "Error mounting image:", output
	sys.exit(1)
	
mounted_path = m.group(1) # /Volumes/htz-tcr

		
print mounted_path, userhome

# -r recursive
# -l copy symlinks as symlinks
# -p preserve permissions
# -t preserve times
# -E copy extended attributes, resource forks
# -v verbose output
# -8 filenames in 8-bit
# / on end of user_path so not synced into directory
result = subprocess.call(['rsync', '-rlptE8', mounted_path + "/", userhome])
if result != 0:
	print "Error: rsync failed"
	subprocess.call(['umount', mounted_path])
	sys.exit(1)
	
result = subprocess.call(["chown", "-R", username + ":Domain Users", userhome])
if result != 0:
	print "Error: chmod failed"
	subprocess.call(['umount', mounted_path])
	sys.exit(1)
	
# unmount disk_image
subprocess.call(['umount', mounted_path])

print "******** Finished *********"
sys.exit(0)