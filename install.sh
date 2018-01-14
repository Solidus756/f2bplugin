# Installation automatisée et configuration du script de monitoring Fail2Ban pour Nagios via NRPE
# Développé par Solidus756

# Déclaration des fonctions

function checkos_finst 
{
	if [ -e /usr/bin/lsb_release ]
then
	distrib=$(lsb_release -i | cut -d ":" -f 2)

	if [ $distrib = Debian ]
		then 
			verdeb=$(cat /etc/debian_version | cut -d "." -f 1)
			fullver=$(cat /etc/debian_version)
			if [ $verdeb -eq 9 ] 
				then
					checksudo
					modjails9
				else
					if [ $verdeb -eq 8 ]
						then 
							checksudo
							modjails87
					fi
			fi
	else
		if [ $distrib = Ubuntu ]
			then
				verubu=$(cat /etc/lsb-release | grep DISTRIB_CODENAME | cut -d "=" -f 2)

				if [ $verubu = xenial ]
					then
						checksudo
						modjails9
					else
						if [ $verubu = trusty ]
							then 
								checksudo
								modjails87
							else
								echo "Version d'Ubuntu non prise en charge,	ce script est compatible avec les versions LTS (14.04 & 16.04)."
						fi
				fi 
			else
				echo -e "\033[1;31mDistribution non prise en charge, ce script est compatible avec les distributions Debian ( 7 - 8 - 9 ) et Ubuntu LTS maintenues à jour ( 14.04 et 16.04 ).\033[0m"
		fi
	fi
else
	verdeb=$(cat /etc/debian_version | cut -d "." -f 1)
	fullver=$(cat /etc/debian_version)
	if [ $verdeb -eq 7 ]
		then
			checksudo7
			modjails87
		else
			echo -e "\033[1;31mVersion non prise en charge, ce script est compatible avec les versions 7 - 8 et 9.\033[0m" 
			exit
	fi
fi
}

function checksudo # Vérification de l'installation de sudo sur le système
{
	sudoinst=$(dpkg-query -l "sudo" | grep sudo | wc -l)
	if [ $sudoinst -eq 1 ]
	then
		echo -e "\033[1;32mParfait, sudo est déjà installé.\033[0m"
	else
		echo "Installation de sudo ..."
		apt-get update -qq && apt-get install sudo -qq	
fi
}

function checksudo7 
{
	checksudo7=$(dpkg-query -l "sudo" | grep "<none>" | wc -l)
	if [ $sudodeb -eq 1 ]
		then
			apt-get update -qq && apt-get install sudo -qq
		else
			echo -e "\033[1;32mParfait, sudo est déjà installé\033[0m"
	fi
}

function checknrpe # Vérification de l'installation de nagios-nrpe-server sur le système
{
	nrpeinst=$(dpkg-query -l "nagios-nrpe-server" | grep nagios-nrpe-server | wc -l)
	if [ $nrpeinst -eq 1 ]
	then
		echo -e "\033[1;32mParfait, nagios-nrpe-server est déjà installé.\033[0m"
	else
		echo "Installation de nagios-nrpe-server..."
		apt-get update -qq && apt-get install nagios-nrpe-server -qq
fi
}

function modsrv
{
	ipnag=$(cat /etc/nagios/nrpe.cfg | grep "allowed_hosts=" | cut -d = -f 2)
	echo -e "L'IP du serveur Nagios actuellement configurée : \033[1;33m$ipnag\033[0m"
	echo -n "Voulez-vous la modifier? [o/N]"
	read ipchoix
	case $ipchoix in
		o)
			echo "Entrez la nouvelle adresse IP du serveur Nagios : "
			read ipnagios

			while [ -z $ipnagios ]
				do 
					echo -e "\033[1;31mAucune IP entrée\033[0m"
					echo "Entrez la nouvelle adresse IP du serveur Nagios : "
					echo " "
					read ipnagios
			done
			
			sed -i "s/allowed_hosts=$ipnag/allowed_hosts=$ipnagios/g" /etc/nagios/nrpe.cfg
			;;
		*)
			echo -e "L'IP restera \033[1;33m$ipnag\033[0m"
			;;
	esac	
}

function checkf2binst
{
	f2binst=$(apt-cache pkgnames | grep fail2ban | wc -l)
	if [ $f2binst -lt 1 ]
		then
			echo -e "\033[1;31mFail2Ban n'est pas installé\033[0m. 
			Installez-le avec la commande apt-get install fail2ban, configurez-le et ensuite relancez le script"
			exit
		else
			echo -e "\033[1;32mFail2Ban est bien installé\033[0m"
		fi
}

function checkf2brun
{
	f2brun=$(ps aux | grep fail2ban.sock | grep -v grep | wc -l)
	if [ $f2brun -eq 1 ]
		then	
			echo -e "\033[1;32mFail2Ban bien est lancé\033[0m"
		else	
			echo "Démarrage de Fail2Ban ..."
			fail2ban-client start
			echo -e "\033[1;32mFail2Ban démarré\033[0m"
	fi
}

function wscript
{
	touch /tmp/check_f2b.sh
	echo '
	# Fichier de configuration du plugin
	 
	STATUS_OK="0" 
	STATUS_WARNING="1" 
	STATUS_CRITICAL="2" 
	STATUS_UNKNOWN="3" 

	# Check si le process Fail2Ban est démarré
	f2b_status=$(ps aux | grep "fail2ban.sock" | grep -v grep | wc -l)

	if [ "$f2b_status" -lt "1" ];
		then 
			echo " !!! Processus de Fail2Ban non trouvé !!! "
			exit $STATUS_CRITICAL
	fi

	# Comptabilisation du nombre de jails actives
	active_jails=$(fail2ban-client status | grep "Number" | cut -f 2)

	if [ "$active_jails" -eq "0" ];
		then	
			echo " --- Aucune jail active ---"
			exit $STATUS_WARNING
		else
			echo "${active_jails} jail(s) active(s)\n"
	fi

	' >> /tmp/check_f2b.sh
}

function modjails9 {
	nbjails=$(fail2ban-client status | grep "Number" | cut -f 2)
	jaillist=$(fail2ban-client status | grep "list" | cut -d ":" -f 2-`expr $nbjails + 1` | sed "s+ +\n+g" | sed 's/,//g')
	vjail="1"
	while [ "$vjail" -lt `expr $nbjails + 1` ]
		do 
			njail=$(echo $jaillist | cut -d " " -f $vjail )
			echo "jail"$vjail"='$njail'" >> /tmp/check_f2b.sh
			echo 'jail'$vjail'_count=$(fail2ban-client status $jail'$vjail' | grep "Currently banned" | cut -f2)' >> /tmp/check_f2b.sh
			echo 'jail'$vjail'_ip=$(fail2ban-client status $jail'$vjail' | grep "Banned" | cut -f 2 | sed "s+ +\n+g")' >> /tmp/check_f2b.sh
			echo 'echo "$jail'$vjail' : $jail'$vjail'_count IP bannies\n$jail'$vjail'_ip\n"' >> /tmp/check_f2b.sh
			echo " "
			vjail=`expr $vjail + 1`
	done

	echo "Déplacement du fichier généré dans le dossier plugin de Nagios"
	mv /tmp/check_f2b.sh /usr/lib/nagios/plugins/check_f2b.sh
	chmod +x /usr/lib/nagios/plugins/check_f2b.sh
}

function modjails87 {
	nbjails=$(fail2ban-client status | grep "Number" | cut -f 2)
	jaillist=$(fail2ban-client status | grep "list" | cut -d ":" -f 2-`expr $nbjails + 1` | sed "s+ +\n+g" | sed 's/,//g')
	vjail="1"
	while [ "$vjail" -lt `expr $nbjails + 1` ]
		do 
			njail=$(echo $jaillist | cut -d " " -f $vjail )
			echo "jail"$vjail"='$njail'" >> /tmp/check_f2b.sh
			echo 'jail'$vjail'_count=$(fail2ban-client status $jail'$vjail' | grep "Currently banned" | cut -f2)' >> /tmp/check_f2b.sh
			echo 'jail'$vjail'_ip=$(fail2ban-client status $jail'$vjail' | grep "IP" | cut -f 2 | sed "s+ +\n+g")' >> /tmp/check_f2b.sh
			echo 'echo "$jail'$vjail' : $jail'$vjail'_count IP bannies\n$jail'$vjail'_ip\n"' >> /tmp/check_f2b.sh
			echo " "
			vjail=`expr $vjail + 1`
	done

	echo "Déplacement du fichier généré dans le dossier plugin de Nagios"
	mv /tmp/check_f2b.sh /usr/lib/nagios/plugins/check_f2b.sh
	chmod +x /usr/lib/nagios/plugins/check_f2b.sh
}

function updnrpe
{
	nrpeconf=$(cat /etc/nagios/nrpe.cfg | grep "command\[check_f2b\]=sudo /usr/lib/nagios/plugins/check_f2b.sh" | wc -l)
	if [ $nrpeconf -eq 1 ]
		then
			echo "Script déjà déclaré dans nrpe.cfg"
		else
			echo "Déclaration du script dans nrpe.cfg"
			echo "command[check_f2b]=sudo /usr/lib/nagios/plugins/check_f2b.sh" >> /etc/nagios/nrpe.cfg
			service nagios-nrpe-server restart
		fi
}
function addsudo
{
	sudoconf=$(cat /etc/sudoers | grep "nagios ALL=NOPASSWD:/usr/lib/nagios/plugins/check_f2b.sh" | wc -l)
	if [ $sudoconf -eq 1 ]
		then
			echo "L'utilisateur nagios est déjà présent dans le fichier sudoers"
		else
			echo "Ajout de l'utilisateur nagios dans le fichier sudoers"
			echo "nagios ALL=NOPASSWD:/usr/lib/nagios/plugins/check_f2b.sh" >> /etc/sudoers
		fi
}
function infos
{
	hn=$(cat /etc/hostname)
	echo "#####################################################################################"
	echo " "
	echo -e "\033[1;32mL'installation du plugin est terminée\033[0m"
	echo "Il ne reste plus qu'à configurer le logiciel de monitoring"
	echo " "
	echo -e "\033[4mConfiguration pour Nagios\033[0m"
	echo " "
	echo "# Fail2Ban Plugin
	define service {
		use   generic-service
		host-name   $hn
		service_description   Fail2Ban
		check_command   check_nrpe!check_f2b"
	echo " "
	echo "Il est possible d'utiliser l'adresse IP au lieu du host-name"
	echo " "
	echo -e "\033[4mConfiguration pour Eyes of Network\033[0m"
	echo " "
	echo '$USER1$/check_nrpe -H $HOSTADDRESS$ -c check_f2b'
	echo " "
	echo "#####################################################################################"
}

function checkoldplugin
{
	if [ -e /usr/lib/nagios/plugins/check_f2b.sh ]
		then 
			echo -e "\033[1;32mAncien fichier du plugin trouvé\033[0m"
		else
			echo -e "\033[1;31mAucun fichier du plugin trouvé, l'avez-vous déplacé?\033[0m"
			exit
	fi
}


function menu
{
	echo -e "\033[34m
	 _______     _ _  ______  ______                 ______  _              _       
	(_______)   (_) |(_____ \(____  \               (_____ \| |            (_)      
	 _____ _____ _| |  ____) )____)  )_____ ____     _____) ) | _   _  ____ _ ____  
	|  ___|____ | | | / ____/|  __  ((____ |  _ \   |  ____/| || | | |/ _  | |  _ \ 
	| |   / ___ | | || (_____| |__)  ) ___ | | | |  | |     | || |_| ( (_| | | | | |
	|_|   \_____|_|\_)_______)______/\_____|_| |_|  |_|      \_)____/ \___ |_|_| |_|
	                                                                 (_____|        
	https://github.com/Solidus756/f2bplugin
	\033[0m"
	echo "Que voulez-vous faire?"
	echo " "
	echo "1. Première installation"
	echo "2. Mise à jour des jails"
	echo "3. Mise à jour de l'IP du serveur de monitoring"
	echo "4. Récupérer les paramètres à entrer dans Nagios"
	echo "5. Quitter"
	echo -n "Choix : "
	read choix
	case $choix in
		1) 	checknrpe
			echo "Sauvegarde de l'ancien fichiers nrpe.cfg en tant que nrpe.cfg.bak"
			cp /etc/nagios/nrpe.cfg /etc/nagios/nrpe.cfg.bak
			modsrv
			checkf2binst
			checkf2brun
			wscript
			checkos_finst
			updnrpe
			addsudo
			infos
			echo -e "\033[1;33mSi vous avez encore besoin des informations ci-dessus, il suffit de relancer le script et de choisir l'option N° 4\033[0m"
			;;
		2) 	checkoldplugin
			echo "Sauvegarde de l'ancienne version du plugin en tant que check_f2b.sh.bak"
			mv /usr/lib/nagios/plugins/check_f2b.sh /usr/lib/nagios/plugins/check_f2b.sh.bak
			wscript
			checkos_finst
			;;
		3) modsrv
			;;
		4) infos
			;;
		5) echo -e "\033[1;32mAu revoir.\033[0m"
			;;
	esac
}

menu








