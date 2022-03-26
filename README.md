Creation of infrastructure based on the Azure service using terraforms.
Used :
scale service (as well as the usual creation of several virtual machines)
postgres service azure (as well as the creation of a virtual machine for this purpose)
built network with two local subnets
NSG security group, limited access ports
And load balancer

------------------------

commands that you will need to run the code and create the structure as shown in the picture. (it is important that you initially created an authorization for an AZURE account on your computer)
* terraform init
* terraform validate
* terraform apply


main file - contains basic infrastructure creation configurations.

var file - contains variables as well as access passwords.


install file - contains the command to install the scale application on the server, including autoloading the javascript application. To install, you need to run the bash install command. at the stage of opening a text editor, you need to insert the local IP configurations, postgres database data, as well as information from the octa account.after saving the configuration, the installation will continue and end at the autoran setup stage


.env - application configuration file is hidden

PORT=8080
HOST=0.0.0.0

HOST_URL=http://your_public)ip:8080
COOKIE_ENCRYPT_PWD=superAwesomePasswordStringThatIsAtLeast32CharactersLong!
NODE_ENV=development

PGHOST=ip_database
PGUSERNAME=username__database
PGDATABASE=name__database
PGPASSWORD=password__database
PGPORT=5432


OKTA_ORG_URL=https://"your_id_dev".okta.com
OKTA_CLIENT_ID=your_id
OKTA_CLIENT_SECRET=your_decret



![week-4-project-env](https://user-images.githubusercontent.com/85096533/160253863-8eb0948c-7267-427f-9804-2b4d51948f0f.png)
