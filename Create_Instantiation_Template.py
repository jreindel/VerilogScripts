#!/usr/bin/env python3
import sys
import io
import re
import time

# Parse input arguements argv[1] = file name argv[2] = debug state
if(len(sys.argv)==2):
    vCode = sys.argv[1]
    debug = 0;
elif(len(sys.argv)==3):
    vCode = sys.argv[1]
    if(int(sys.argv[2])>0):
        debug = int(sys.argv[2])
    else:
        debug = 0
else:
    print("Wrong number of input argurmets. Usage is:\n")
    print("./Create_Instantiation_Template.py <file> <debug>\n")
    print("<file> is required; verilog code for the module you want a template of.\n")
    print("<debug> is optional; 0 for off (default), 1 for some, 2 for verbose")
    exit()

line = []
with io.open(vCode,mode='r') as file:
    i=0
    line.append(file.readline())
    while(line[i] != ""):
        line.append(file.readline())
        i+=1

# Find begining and end of module port declaration and moduel name
modName = ""
modStart = 0
modEnd = 0
for i in range(len(line)):
    comLine = line[i].split('//')
    if '[' in comLine[0]:
            curLine = comLine[0].replace(']','[').split("[")
            curLine = curLine[0] + '[' + curLine[1].replace(' ','') + ']' + curLine[2]
            if len(comLine)==2:
                curLine = curLine + '// ' + comLine[1]
            line[i] = curLine
    curLine = line[i].strip().split(' ') # strip white space, split by space
    if(curLine[0] == "module"): # module declaration start
        modStart = i
        modName = curLine[1].strip('(#')
    if(curLine[len(curLine)-1] == ");"): # module declaration end
        modEnd = i
        break
    
if(debug):
    print("Module Name: ",modName)
    print("Port declaration begins on line: ",modStart+1)
    print("Port delcaration ends on line: ",modEnd+1)

# Parse port declaration information from the file
parName = []
parVal = []
parComment = []
direction = []
dataType = []
size = []
varName = []
comment = []
for i in range(modStart,modEnd+1):
    comLine = line[i].split('//') # Split Comments
    comLine[0] = re.sub(' +',' ',comLine[0])
    curLine = re.split(", |,| ",comLine[0].strip()) # Divide port info
#    l = i-modStart
    if(debug > 1): # verbose listing of divided line info
        print(str(i+1)+' '+str(curLine))
    if(curLine): # information on line besides comments
        for j in range(len(curLine)):
            if(curLine[j]=="parameter"): # Locate parameter inputs
                parName.append(curLine[1])
                parVal.append(curLine[3])
                if(len(comLine) > 1):
                    parComment.append(comLine[1].strip())
                else:
                    parComment.append("")
            if(curLine[j]=="input" or curLine[j]=="output"): # Locate inputs and outputs to begin parsing
                if(curLine[j+2][0] == "["): # multibit port
                    for k in range(3,len(curLine)-j):
                        if(curLine[j+k]=="input" or curLine[j+k]=="output"):
                            break
                        if(curLine[j+k]):
                            direction.append(curLine[j])
                            dataType.append(curLine[j+1])
                            size.append(curLine[j+2])
                            varName.append(curLine[j+k])
                            if(len(comLine) > 1):
                                comment.append(comLine[1].strip())
                            else:
                                comment.append("")
                        
                else: # Single bit port
                    for k in range(2,len(curLine)-j):
                        if(curLine[j+k]=="input" or curLine[j+k]=="output"):
                            break
                        if(curLine[j+k]):
                            direction.append(curLine[j])
                            dataType.append(curLine[j+1])
                            size.append("")
                            varName.append(curLine[j+k])
                            if(len(comLine) > 1):
                                comment.append(comLine[1].strip())
                            else:
                                comment.append("")
    else:
        direction.append("")
        dataType.append("")
        size.append("")
        varName.append("")
        comment.append("")
        
# Verbose print of number of elements in each list
if(debug >1): 
    print("\ndirection: "+str(len(direction))+", dataType: "+str(len(dataType))+", size: "+str(len(size))+", varName: "+str(len(varName))+", comment: "+str(len(comment))+", parName: "+str(len(parName))+", parVal: "+str(len(parVal))+", parComment: "+str(len(parComment)))

# Debug print of port information
if(debug): 
    print("\nPorts:")
    for i in range(len(direction)):
        #if(direction[i]):
        print(direction[i],"\t",dataType[i],"\t",size[i],varName[i],"\t\\\\",comment[i])
        
saveDir = vCode.split(".v")[0]+".veo"     
print("\nSaved to: ",saveDir)

# Write file out
with io.open(saveDir,mode='w') as fout:
    # File headder
    fout.write("//////////////////////////////////////////////////////////////////////////////////\n")
    fout.write("// This file was generated by ./Create_Instantiation_Template.py <file> <debug> //\n")
    fout.write("// The following must be inserted into your Verilog file for this core to be    //\n")
    fout.write("// instantiated. Change the instance name and port connections (in parentheses) //\n")
    fout.write("// to your own signal names.                                                    //\n")
    fout.write("// Created: "+str(time.ctime(time.time()))+"                                    \n")
    fout.write("//////////////////////////////////////////////////////////////////////////////////\n")
    fout.write("\n//----------- Begin Cut here for INSTANTIATION Template -------------// INST_TAG\n")
    
    # Instantiation Template
    fout.write(modName+"#(\n")
    itt = len(parName)
    for i in range(itt):
        if(i==itt-1):
            fout.write("\t."+parName[i]+"("+parVal[i]+")")
        else:
            fout.write("\t."+parName[i]+"("+parVal[i]+"),")
        if(parComment[i]):
            fout.write("\t// "+parComment[i]+"\n")
        else:
            fout.write("\n")
    fout.write(") your_instance_name (\n")
    itt = len(direction)
    for i in range(itt):
        if(direction[i]):
            if(i==itt-1):
                fout.write("\t."+varName[i]+"("+varName[i]+")\t// "+direction[i]+" "+size[i]+" "+varName[i])
            else:
                fout.write("\t."+varName[i]+"("+varName[i]+"),\t// "+direction[i]+" "+size[i]+" "+varName[i])
            if(comment[i]):
                fout.write(" ("+comment[i]+")\n")
            else:
                fout.write("\n")
    fout.write(");\n")  
    
    # File footer  
    fout.write("// INST_TAG_END -------- End INSTANTIATION Template ---------\n")    
    
    
