# Remove old files
rm -f release-notes.json
rm -f release-notes.html


JIRA_URL=https://atlassian.jira.com
JIRA_KEY=TEST
# Base64 username and password
JIRA_CREDENTIALS=$(echo -n 'test:test' | base64)
# The component name according to JIRA
JIRA_COMPONENT="Shop"

# Use HTTP get to the JIRA search endpoint
curl -X POST -H "Authorization: Basic $JIRA_CREDENTIALS" -H "Content-Type: application/json" --data '{"jql":"project='$JIRA_KEY' AND issuetype in standardIssueTypes() AND component='$JIRA_COMPONENT' AND status=Closed AND fixVersion=latestReleasedVersion()"}' "$JIRA_URL/rest/api/2/search" > release-notes.json

# Parse JSON
cat > parse_json.py <<_EOF_
import json
import codecs
with codecs.open( "release-notes.json", "r", "utf-8" ) as json_data:
    parsed_json = json.load(json_data)
    issues = parsed_json['issues']
    print "<html><body>"
    for issue in issues:
        issue_url= '$JIRA_URL/browse/'+ issue['key']
        summery = issue['fields']['summary']
        html_line='<div><a href="'+ issue_url +'">'+ issue_url + '</a> - '+ summery +'</div>'
        print(html_line.encode('utf-8'))
    print "</body></html>"
_EOF_
python2 parse_json.py  > release-notes.html

# Send email
cat > send_email.py <<_EOF_
import smtplib
sender = 'devteam@mycompany.com'
receivers = ['service-manager@mycompany.com','devteam@mycompany.com']
email_content=open("release-notes.html", "r").read()
message = """From: Shop team <devteam@mycompany.com>
To: Service Manager <service-manager@mycompany.com>
CC: Dev team <devteam@mycompany.com>
MIME-Version: 1.0
Content-type: text/html
Subject: Latest Release $JIRA_COMPONENT
Hi Service Manager,
<br/>
Below you'll find the release notes of our upcoming release.
<br/>
"""
message = message + email_content
try:
   smtpObj = smtplib.SMTP('localhost', 25)
   smtpObj.sendmail(sender, receivers, message)
   print "Successfully sent email"
except SMTPException:
   print "Error: unable to send email"
_EOF_
python2 send_email.py
