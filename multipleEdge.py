import time
import os
import random


filePath = "Variables.ps1"

def readFile():
    with open('public_ips.txt', 'r') as f:
        ip = f.read().splitlines()
    return ip


def countdown(seconds):
    for i in range(seconds, 0, -1):
        if i % 10 == 0: # display time remaining every 10 seconds
            print(f"Time left: {i} seconds.")
        time.sleep(1)
    print("Execution starting now.")

def powershellExc():
    os.system(f"pwsh AutodeployEA.ps1 Variables.ps1")

def overwrite_value_in_file(file_path, key, new_value):
    with open(file_path, 'r') as f:
        content = f.read()

    key_position = content.find(key)
    if key_position == -1:
        return

    line_end_position = content.find('\n', key_position)
    if line_end_position == -1:
        line_end_position = len(content)

    new_line = f'{key} = {new_value.strip()}'
    new_content = content[:key_position] + new_line + content[line_end_position:]

    with open(file_path, 'w') as f:
        f.write(new_content)
def execute():
    ip_list=readFile()
    for ip in ip_list:
        ipKey="EdgeApplianceIpAddress"
        edgeApplianceIP='"'+ip.strip()+'"'
        overwrite_value_in_file(filePath,ipKey,edgeApplianceIP)

        nameKey="EdgeApplianceName"
        id = random.randint(1000,9999)
        EdgeApplianceName='"filer-'+str(id)+'"'
        overwrite_value_in_file(filePath,nameKey,EdgeApplianceName)
        # countdown(120)
        powershellExc()

    # for ip in ip_list:

execute()
