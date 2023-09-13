# **DOCKERIZED-SOLUTIONS-CHALLENGE** 

This is a solution to the dockerized solutions challenge on https://hackattic.com/challenges/dockerized_solutions

## **PREREQUISITES**

+ Domain name
+ A CA-signed SSL certificate
+ A VM with appropriate firewall rules configured
+ Map the IP address of the VM to the domain name as an A Record
+ Install docker on the VM

## **TLDR**
1. **STEP1** 
+ Create certificate folders 
+ Create and configure Docker Registry
+ Retrieve challenge credentials

2. **Push the Image**
+ Initiate the push by making a POST request to `/_/push/<trigger_token>`, and include the `registry_host` within the JSON payload.

3. **Obtain the Solution:**
+ Fetch the uploaded image from your registry.
+ Set the `IGNITION_KEY` environment variable using the value given in the problem JSON.
+ Launch the container with the image you've fetched.

4. **Submit the Solution**
+ Provide the solution by making a POST request to `/challenges/dockerized_solutions/solve`, and incorporate the secret key, which the container returned, into the JSON payload.

### **STEP 1:**
**Create certificate storage folders**

<pre>
#create folders
mkdir store
cd store
mkdir auth
mkdir certs
</pre>

**Copy the certificates and private key from your local machine to the Vm**

<pre>
gcloud compute scp PATH_TO_FOLDER_CONTAINING_CERTS_AND_ PRIVATE_KEY/* VM_NAME:HOMEDIR/test/certs/ --zone=$ZONE
</pre>

**Setting up Docker with TLS**

<pre>
sudo mkdir -p /etc/docker/certs.d/$DOMAIN_NAME:443
sudo cp HOMEDIR/test/certs/domain.crt /etc/docker/certs.d/$DOMAIN_NAME:443/
sudo cp /home/Home/test/certs/domain.cert /etc/docker/certs.d/$DOMAIN_NAME:443/
sudo cp /home/Home/test/certs/domain.key /etc/docker/certs.d/$DOMAIN_NAME:443/
sudo cp /home/Home/test/certs/SubCA.crt /etc/docker/certs.d/$DOMAIN_NAME:443/
sudo cp /home/Home/test/certs/Root_RSA_CA.crt /etc/docker/certs.d/$DOMAIN_NAME:443/
sudo systemctl restart docker
</pre>


**Retrieve credentials from challenge**

<pre>
# install jq
sudo apt-get update
sudo apt-get install jq
</pre>

**Create a credentials_json.sh file**

<pre>
#!/bin/bash

# Define the URL to fetch the JSON from
URL="https://hackattic.com/challenges/dockerized_solutions/problem?access_token=$ACCESS_TOKEN"

# Use curl to fetch the JSON data and store it in a variable
JSON=$(curl -s "$URL")

# Parse the JSON data using a tool like jq and extract the variables
USER=$(echo "$JSON" | jq -r '.credentials.user')
PASSWORD=$(echo "$JSON" | jq -r '.credentials.password')
IGNITION_KEY=$(echo "$JSON" | jq -r '.ignition_key')
TOKEN=$(echo "$JSON" | jq -r '.trigger_token')

# Print the export commands
echo "export USERNAME='$USER'"
echo "export PASSWORD='$PASSWORD'"
echo "export IGNITION_KEY='$IGNITION_KEY'"
echo "export TOKEN='$TOKEN'"
</pre>

**Execute the script**

<pre>
bash credentials_json.sh > credentails_exports.sh
</pre>

**Load the variables into the terminal**

<pre>
source credentials_exports.sh
</pre>

**Verify the accessibility of variables:**
<pre>
echo $USERNAME echo $PASSWORD echo $IGNITION_KEY echo $TOKEN
</pre>

**Configure Authentication**

<pre>
htpasswd -Bbn $USERNAME $PASSWORD > auth/htpasswd
</pre>

**Granting Docker Command Access Without Sudo**

<pre>
sudo usermod -aG docker $USER
</pre>

**Create and Configure the Docker Registry**

<pre>
docker run -d -p 443:443 --name=local-registry --restart=always \
  -v /HOMEDIR/test/certs:/certs \
  -v /HOMEDIR/test/auth:/auth \
  -e "REGISTRY_AUTH=htpasswd" \
  -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
  -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
  -e REGISTRY_HTTP_ADDR=0.0.0.0:443 \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.cert \
  -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
  registry:2
</pre>

**VERIFICATION**

**Authenticating to the Docker Registry**

<pre>
docker login $DOMAIN_NAME -u $USERNAME -p $PASSWORD
</pre>

**Ensure the Registry is reachable**

<pre>
curl https://$DOMAIN_NAME:443
</pre>

**Stop the Registry**

<pre>
docker stop $CONTAINER_ID
</pre>

**Execute the script**

<pre>
bash credentials_json.sh > credentails_exports.sh
</pre>

**Load the variables into the terminal**

<pre>
source credentials_exports.sh
</pre>

**Verify the accessibility of variables:**
<pre>
echo $USERNAME echo $PASSWORD echo $IGNITION_KEY echo $TOKEN
</pre>

**Configure Authentication**

<pre>
htpasswd -Bbn $USERNAME $PASSWORD > auth/htpasswd
</pre>

**Start the Registry**

<pre>
docker start $CONTAINER_ID
</pre>

### **STEP 2:**
**TRIGGER THE PUSH**

<pre>
curl -X POST https://hackattic.com/_/push/$TOKEN -d '{"registry_host": "$DOMAIN_NAME"}'
</pre>

**Retrieve List of Repositories**

<pre>
curl -u $USERNAME:$PASSWORD -X GET https://$IP/v2/_catalog
</pre>

**Retrieve List of Tags in the Repository**

<pre>
curl -u $USERNAME:$PASSWORD -X GET https://$IP/v2/hack/tags/list
</pre>

**Pull the Image from the Registry**
<pre>
docker pull $DOAMIN_NAME/IMAGE:TAG
</pre>

**Run the container**
<pre>
docker run -e IGNITION_KEY=$IGNITION_KEY --name YOUR_CHOSEN_NAME $DOMAIN_NAME/IMAGE:TAG
</pre>
## **Submit the solution**
**create a script file**
<pre>
#!/bin/bash

# Extracted secret key from container logs
SECRET_KEY="SECRET"
# Endpoint URL
URL="https://hackattic.com/challenges/dockerized_solutions/solve?access_token=$ACCESS_TOKEN"
PAYLOAD="{\"secret\":\"$SECRET_KEY\"}"

# Make the POST request
curl -X POST -H "Content-Type: application/json" -d "$PAYLOAD" "$URL"
</pre>