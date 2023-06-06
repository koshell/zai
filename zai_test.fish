#!/usr/bin/env fish

function pause
	set -f cmd_string ( string join -- ' ' \
		'read -n1 -r -s -p'			\
		"\"$( string replace -a 	\
				'"' 				\
				'\"' 				\
				"$argv[1]" 			\
		)\"" ) 
	bash -c "$cmd_string"
	echo
	return
end

function install_omf
	echo -e '  Installing \'Oh My Fish\' with the \'pure\' theme into VM...\n'
	ssh -t -A -o StrictHostKeyChecking=no -o LogLevel=ERROR -o 'UserKnownHostsFile /dev/null' root@192.168.122.82 \
		-- 'curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install \
				--output /tmp/omf-install.fish > /dev/null; echo; \
			chmod +x /tmp/omf-install.fish; \
			fish /tmp/omf-install.fish --noninteractive; \
			fish -c "omf install pure";'
	echo -e '\n  Finished installing the \'pure\' theme'
	return
end

function reboot_on_exit --on-event fish_exit
	echo '  Telling VM to reboot...'
	ssh -t -A -o StrictHostKeyChecking=no -o LogLevel=ERROR -o "UserKnownHostsFile /dev/null" \
		root@192.168.122.82 -- 'reboot;' 
	echo '  Done!'
end

function reboot_on_cancel --on-event fish_cancel
	# I think this might of been creating an infitite loop?
	# reboot_on_exit
end

echo -en "\n\n  $(tput sgr0; tput setaf 2)Connecting to VM...$(tput sgr0)\n\n"
printf '%s' "  Waited 0 seconds for the VM to respond..."
set start_time ( date +%s )
set last_time ( date +%s.%3N )
while not nc -w 1 -z 192.168.122.82 22
	# For most the boot process this will just timeout
	# but there is a period right before sshd starts accepting
	# connections that connections are actively refused.
	#
	# The following mostly just ensures that even if we get a negative responce
	# earlier then 1 second that we still wait 1 second before trying again
	set -l delta "$( math -s3 $( date +%s.%3N ) - $last_time )"
	if test $delta -lt 1
		sleep "$(math -s3 1 - $delta)"
	end
	set last_time ( date +%s.%3N )

	# Prints the amount of time spent waiting for the VM to come online
	tput hpa 0; tput el; printf '%s' \
		"  Waited $(math -s0 ( date +%s ) - $start_time ) seconds for the VM to respond..."
end
echo -en '\n\n'
rsync -ar -e 'ssh -o StrictHostKeyChecking=no -o LogLevel=ERROR -o "UserKnownHostsFile /dev/null"' ./* root@192.168.122.82:zai > /dev/null
ssh -t -A -o StrictHostKeyChecking=no -o LogLevel=ERROR -o "UserKnownHostsFile /dev/null" root@192.168.122.82 \
	-- 'bash ./zai/1_run-livecd.bash;'
echo
pause "Press any key to begin 'Oh My Fish' installation..."
echo
install_omf

ssh -t -A -o StrictHostKeyChecking=no -o LogLevel=ERROR -o "UserKnownHostsFile /dev/null" root@192.168.122.82 \
	-- 'fish -i; \
		arch-chroot /mnt /zai/2_run-chroot.fish; \
		arch-chroot /mnt /usr/bin/fish; \
		reboot;'
