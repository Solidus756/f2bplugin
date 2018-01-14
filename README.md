# f2bplugin

*Il s'agit d'un script automatisé qui installe le nécessaire à la surveillance de Fail2Ban sur Nagios ou Eyes of Network*

**Distributions et versions prises en charge :**
* Debian 7 à 9
* Ubuntu 14.04 (LTS) & 16.04 (LTS)

Prérequis :
------------
* Une des distributions et versions ci-dessus.
* Fail2Ban installé et configuré.
* Git

Installation :
---------------

L'installation est on ne peut plus simple :

* `# cd /tmp`
* `# git clone https://github.com/Solidus756/f2bplugin.git`
* `# cd /f2bplugin`
* `# chmod +x install.sh`
* `# ./install.sh`
  
Un menu va s'afficher
  
* `1. Première installation :` C'est par là qu'il faut commencer, c'est le script complet qui fait le nécessaire pour mettre en place le plugin
* `2. Mise à jour des jails :` A utiliser si il y a eu des modifications (ajout/suppression de jails), le script sera automatiquement mis à jour.
* `3. Mise à jour de l'IP du serveur de monitoring :` A utiliser si le serveur Nagios change d'IP
* `4. Récupérer les paramètres :` Il s'agit tout simplement des commandes à entrer dans Nagios ou EoN pour voir le plugin.
* `5. Quitter :` Au revoir
