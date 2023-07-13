<h2> put the setupwp.sh file into /var/www/ </h2>

<h4>// run these commands first:</h4>
<p>sudo apt-get install dos2unix </p>
<p>sudo dos2unix setupwp.sh </p>
<p>sudo chmod +x setupwp.sh </p>

<h4>// then u can run the script:</h4>
<p>./setupwp.sh</p>

the script installs latest wordpress, sets up nginx config for the domain and sql database and username. 
