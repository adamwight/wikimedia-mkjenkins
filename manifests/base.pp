Exec {
	path => ["/usr/bin", "/bin", "/usr/sbin", "/sbin", "/usr/local/bin", "/usr/local/sbin"]
}


File { owner => vagrant, group => vagrant, mode => 0644 }

class generic { 
	group { 'puppet':
		ensure => 'present'
	}

	file { "/etc/puppet/modules":
		ensure => 'directory',
	}

	# Replace geo-specific URLs with generic ones.
	exec { 'fix-sources':
		command => "sed -i'' -e 's/us\\.archive/archive/g' /etc/apt/sources.list"
	}

	exec { 'apt-update':
		require => Exec['fix-sources'],
		command => '/bin/true'; #/usr/bin/apt-get update';
	}

	File { owner => 0, group => 0, mode => 0644 }
	file { '/etc/motd':
	  content => "Welcome to the Jenkins Vagrant image. Do <XYZ> to start the server, then browse to <ZZZ>!
      
Please run
    sudo puppet apply /vagrant/manifests/base.pp
to apply the most recent puppet manifest; run    
    /home/vagrant/gitsetup
to setup git name & email.
"}
}

class git {
	package {"git":
		require => Exec["apt-update"],
		ensure => present,
	}

	file { "/home/vagrant/gitsetup":
		content => "if [ `git config user.name | wc -l` -eq 0 ]\nthen\n    echo\n    echo Git has not been configured yet!\n    echo\n    git config --global user.name \"`read -p 'Full name (git): '; echo \$REPLY`\"\n    git config --global user.email \"`read -p 'Email address (git): '; echo \$REPLY`\"\nfi"
	}

}

class dependencies {
	package {"mc":
		require => Exec["apt-update"],
		ensure => present;
	}

	package {"screen":
		require => Exec["apt-update"],
		ensure => present;
	}

	package { "python2.7":
		require => Exec["apt-update"],
		ensure => present;
	}

	package { "python-virtualenv":
		require => Exec["apt-update"],
		ensure => present;
	}

	package { "python-psycopg2":
		require => Exec["apt-update"],
		ensure => present;
	}
    
    package { "default-jre":
		require => Exec["apt-update"],
		ensure => present;
	}
    
    package { "vim":
        require => Exec["apt-update"],
        ensure => present;
    }
    
    package { "curl":
        require => Exec["apt-update"],
        ensure => present;
    }
    
	include git
}

class devenv {
	exec { "jenkinsclone":
        creates => "/home/vagrant/jenkins",
        cwd => "/home/vagrant",
        command => "git clone https://gerrit.wikimedia.org/r/p/integration/jenkins.git jenkins",
        user => "vagrant",
        require => [Package["git"]],
	}
    
    exec { "jenkinswar":
        creates => "/home/vagrant/jenkins/jenkins.war",
        cwd => "/home/vagrant/jenkins",
        command => "wget http://mirrors.jenkins-ci.org/war/latest/jenkins.war",
        user => "vagrant",
        require => Exec["jenkinsclone"],
    }
    
    file { "/home/vagrant/jenkins/jenkins-daemon.sh":
        mode => 755,
        owner => "vagrant",
        source => "/vagrant/manifests/jenkins-daemon.sh",
    }
    
    
}

include generic
include dependencies
include devenv
