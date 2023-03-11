#!/usr/bin/env python3
import sys
import io
import re
import time

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
    print("Wrong number of input argurmets.\n\nUsage is:")
    print("./Create_Testbench.py <file> <debug>\n")
    print("<file> is required; verilog code for the module you want a testbench of.\n")
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
    print("\ndirection: "+str(len(direction))+", dataType: "+str(len(dataType))+", size: "+str(len(size))+", varName: "+str(len(varName))+", comment: "+str(len(comment))+", parName: "+str(len(parName))+", parVal: "+str(len(parVal))+",arComment: "+str(len(parComment)))

# Debug print of port information
if(debug): 
    print("\nPorts:")
    for i in range(len(direction)):
        #if(direction[i]):
        print(direction[i],"\t",dataType[i],"\t",size[i],varName[i],"\t\\\\",comment[i])

# Save dir/filename
saveDir = ""
Dir = vCode.split("/")
Dir[len(Dir)-1] = "testbench_"+Dir[len(Dir)-1]
if(len(Dir)>1):
    for i in range(len(Dir)-1):
        saveDir += "/"
        saveDir += Dir[i+1]
else:
    saveDir = Dir[0]

print("\nSaving to: ",saveDir)
    
# Write file out
with io.open(saveDir,mode='w+') as fout:
    # Header
    fout.write("`timescale 1ns / 1ps\n")
    fout.write("//////////////////////////////////////////////////////////////////////////////////\n")
    fout.write("// Company: \n")
    fout.write("// Engineer: \n")
    fout.write("// \n")
    fout.write("// Create Date: "+str(time.ctime(time.time()))+"\n")
    fout.write("// Design Name: \n")
    fout.write("// Module Name: "+modName+"\n")
    fout.write("// Project Name: \n")
    fout.write("// Target Devices: \n")
    fout.write("// Tool Versions: \n")
    fout.write("// Description: \n")
    fout.write("// \n")
    fout.write("// Dependencies: \n")
    fout.write("// \n")
    fout.write("// Additional Comments:\n")
    fout.write("// \n")
    fout.write("//////////////////////////////////////////////////////////////////////////////////\n")
    fout.write("module testbench_"+modName+"#(\n")
    itt = len(parName)
    for i in range(itt):
        if(i==itt-1):
            fout.write("\tparameter "+parName[i]+" = "+parVal[i])
        else:
            fout.write("\tparameter "+parName[i]+" = "+parVal[i]+",")
        if(parComment[i]):
            fout.write("\t// "+parComment[i]+"\n")
        else:
            fout.write("\n")
    fout.write(")();\n\n")
    # input ports
    fout.write("\t// inputs\n")
    for i in range(len(direction)): 
        if(direction[i]=="input"):
            fout.write("\treg "+str(size[i])+str(varName[i])+";\n")
    # output ports        
    fout.write("\n\t// outputs\n")
    for i in range(len(direction)):
        if(direction[i]=="output"):
            fout.write("\twire "+str(size[i])+str(varName[i])+";\n")
    fout.write("\n\t// unit under test\n\t")
    # Instantiation Template
    fout.write(modName+"#(\n")
    itt = len(parName)
    for i in range(itt):
        if(i==itt-1):
            fout.write("\t."+parName[i]+"("+parName[i]+")")
        else:
            fout.write("\t."+parName[i]+"("+parName[i]+"),")
        if(parComment[i]):
            fout.write("\t// "+parComment[i]+"\n")
        else:
            fout.write("\n")
    fout.write(") uut (\n")
    itt = len(direction);
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
    fout.write("\t);\n")  
    # Clock
    fout.write("\n\t// Freerunning Clock(s)?\n")
    fout.write("//\tinitial begin\n")
    fout.write("//\t\tclk = 0;\n")
    fout.write("//\t\tforever begin\n")
    fout.write("//\t\t\t#0.5;// 1ns cycle\n")
    fout.write("//\t\t\tclk = ~clk;\n")
    fout.write("//\t\tend\n")
    fout.write("//\tend\n")
    fout.write("\n\t// Test Sequence\n")
    fout.write("\tinitial begin\n")
    fout.write("\t\t// Initialize inputs\n")
    for i in range(len(direction)): 
        if(direction[i]=="input"):
            fout.write("\t\t"+str(varName[i])+" = ")
            if(size[i]):
                fout.write("'b0;\n")
            else:
                fout.write("0;\n")
    fout.write("\t\t// Wait for clear to finish\n\t\t#100;\n")
    fout.write("\n\t\t// Add stimulus here\n")
    fout.write("\t\t\n")
    fout.write("\t\t\n")
    fout.write("\t\t$finish;\n")
    fout.write("\tend\n")
    fout.write("endmodule\n")
    

    
