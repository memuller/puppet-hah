class hentaiathome (
		$client_id,
		$client_key,
		$ensure = 'present',
		$version = '1.0.10',
		$server_dir = '/usr/local/lib/hath',
		$log = '/var/log/hath.log',
		$user = 'hath'
	) {

	$running = $ensure ? {
		absent => 'stopped',
		default => 'running'
	}

	$url = "http://hentaiathome.net/get/HentaiAtHome_$version.zip"
	$client_auth_string = "$client_id-$client_key"

	Exec { 
		path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin/" ]
	}
	File { owner => $user, group => $user }

	# install JRE, unzip, and get.
	package {['default-jre', 'unzip', 'wget']:}

	# adds an user for running the server.
	add_user { "$user": }

	# creates the server dir.
	file { "${server_dir}":
		ensure => 'directory',
		owner => $user,
		group => $user,
		require => User[$user]
	}

	# downloads H@H.
	exec { get_HaH:
		command => "wget '$url' -O '$server_dir/H@H.zip'",
		creates => "$server_dir/H@H.zip",
		require => [ 
			File[$server_dir], Package['wget']
		]
	}

	# unzips H@H.
	exec { unzip_HaH:
		command => 'unzip -o H@H.zip',
		cwd => $server_dir,
		require => [
			Exec['get_HaH'], Package['unzip']
		]
	}

	# creates H@H data folder.
	file {"${server_dir}/data":
		ensure => 'directory',
		require => File[$server_dir]
	}

	# creates H@H auth file.
	file { "${server_dir}/data/client_login":
		ensure => 'file',
		content => $client_auth_string,
		require => File[$server_dir]
	}

	# creates a log file, if needed;
	# uses /dev/null otherwise.
	if ($log){
		file { $log:
			ensure => 'present',
			mode => '644'
		}
		$log_target = $log	
	} else {
		$log_target = '/dev/null'
	}

	# creates server start script.
	file { "${server_dir}/start.sh":
		ensure => 'present',
		mode => '700',
		content => template('hentaiathome/start.sh.erb'),
		require => Exec['unzip_HaH']
	}

	# implements a basic, simple service.
	service {'hah':
		ensure => $running,
		provider => 'base',
		binary => "$server_dir/start.sh &> $log_target &",
		require => File["$server_dir/start.sh"]
	}
}