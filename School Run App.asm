.data
# Prompt message to tell what feature user are currently in
promptMsg:   		.asciiz "Please enter the feature you are using (1 for drop off, 2 for pick up): " # Print out a prompt message for user to key in the feature they are using
dropOffMsg:  		.asciiz "You are now in the drop off action area.\n" 
pickUpMsg:		.asciiz "You are now in the pick up action area.\n"
validationDropOff: 	.asciiz "Still Dropoff? (1 for no, 2 for yes): "
validationPickUp:	.asciiz "Still PickUp? (1 for no, 2 for yes): "
exitMsg: 		.asciiz "You are going to exit the program. Thank you!"
newline:		.asciiz "\n"

# Car Detection Message
carPresence: 		.asciiz "\nCars Approaching \n"
trafficVehicles: 	.asciiz "Number of cars in the area: "
nearestCarDistance:	.asciiz "Nearest car from pickup point distance(1m/5m/10m): "
noPlate:		.asciiz "No. Plate: "
carInfo:		.asciiz "Car Information\n"
plate_no: 		.space 8  # Assuming a maximum length of 7 characters for the plate number
registered_plates:	.asciiz "WXG5722"	 
registeredMessage: 	.asciiz "\n\nThe vehicle plate number is Verified \n"
unregisteredMessage: 	.asciiz "\n\nThe car plate number is not registered \n" 
notifyMessage:		.asciiz "Vehicle picking up students is coming!\n"
eta:			.asciiz "\nEta:"
time:			.word 0

# Student ID message
studentId:		.word 1001
studentName:		.asciiz "Tengku Zarul"
studentStatus:		.word 0
attendanceInput: 	.asciiz "\nThe students have been dropped and students are approaching the gate \n"
invalidIDMsg: 		.asciiz "Invalid ID of Students \n"
studentAttend: 		.asciiz "\n\nStudent attendance has been updated to PRESENT \nHave a nice day!\n"
studentReturn: 		.asciiz "\n\nStudent attendance has been updated to GONE BACK HOME \nHave a nice day!\n"
scanRfidDropOff:	.asciiz "Please scan your nametag first for the attendance.\n"
scanRfidPickUp:		.asciiz "Please scan your nametag before going back. \n"
name:			.asciiz "Name: "
studentID:		.asciiz "\nStudent's ID: "
returnMsg:		.asciiz " have gone back home\n"

# Time Message
timeMsg: 		.asciiz "\nIs it 8:30 A.M. now? Enter 1 for yes, 0 for no): "
studentStatusMsg:	.asciiz "\nMajority students have gone back home? (Enter 1 for yes, 0 for no): "

.text
.globl main

main: 
	la $a0, promptMsg
	jal printMsg
	
	li $v0, 5				# Ask user to choose pick up or drop off feature
	syscall
	move $t0, $v0				# Use $t0 for beq 
	
	beq $t0, 1, dropOff			# If user input 1, then go to drop off feature
	beq $t0, 2, pickUp			# If user input 2, then go to pick up feature
	j main

# Drop Off Feature	
dropOff:
	la $a0, dropOffMsg             		# Display drop off message
	jal printMsg
	
	la $a0, carPresence			# Display detecting cars' presence message
	jal printMsg
	
	la $a0, trafficVehicles			# Display how many vehicles within the area
	jal printMsg

# Random number generator			
	li $v0, 42				# Syscall to generate random number to randomize number of cars in the school area
	li $a1, 20				# Only until 20 because school area is packed and small
	syscall
	move $s1, $a0
	
	# Print out the number of cars with pointing to $s1
	li $v0, 1
	la $a0, 0($s1)
	syscall
	
	la $a0, newline
	jal printMsg
	
	la $a0, noPlate				# Display message about plate number
	jal printMsg
	
    	#Read input from sensor (car plate number)
    	li $v0, 8            			# To read the plate number string
    	la $a0, plate_no     			
    	li $a1, 8            			# Only 8 as maximum because Malaysians usually have 7 character
    	syscall
    
    	# Determine the length of the detected plate number dynamically
    	la $t2, plate_no     			# Load the address of the detected plate
    	li $t3, 0            			# Initialize the length counter to 0

detect_length_loop:
    	lb $t4, 0($t2)        			# Load a character from the detected plate
    	beqz $t4, check_plate 	 		# If the character is zero, end of string is reached
    	addi $t2, $t2, 1      			# Move to the next character in the detected plate
    	addi $t3, $t3, 1      			# Increment the length counter
    	j detect_length_loop  			# Check the next character
    
check_plate:
    # Check if the plate number detected exists in the school database
    	la $t1, registered_plates		# Load the address of the registered plates
    	la $t2, plate_no			# Load the address of the detected plate
    
compare_database:
    	lb $t3, 0($t1)				# Load a character from the registered plates from the database
    	beqz $t3, registeredVehicle		# If the character is zero, end of list is reached
  
    	lb $t4, 0($t2)				# Load a character from the detected plate
    	bne $t3, $t4, not_matched		# If the characters do not match, branch to not_matched
    
    	addi $t2, $t2, 1
    	addi $t1, $t1, 1			# Increment counter to move to next character in the registered plates
    	j compare_database			# Check the next character

not_matched:
    # Check if the entire plate has been compared
    	beqz $t4, registeredVehicle		# If the character is zero, the entire detected plate has been matched
    	j unregisteredVehicle			# Otherwise, branch to not_registered	
	
registeredVehicle: 
	# Display Message telling the vehicles are registered
	la $a0, registeredMessage
	jal printMsg
	
	j checkID				# Proceed to check students' ID
	
unregisteredVehicle:
	# Display Message telling the vehicles are unregistered
	la $a0, unregisteredMessage
	jal printMsg
	
	j dropOff				# Go to dropOff loop again
	
checkID:
	# Check validation of students ID to update the attendance database
	la $a0, attendanceInput			# Display students came
	jal printMsg
	
	la $a0, scanRfidDropOff			# Display message for students to scan the nametag
	jal printMsg
	
    	la $a0, studentID			# Display Student ID: 
    	jal printMsg
    	
    	# Get the student ID from the user
    	li $v0, 5
    	syscall
    	move $t1, $v0   # Save the student ID

    	# Search for the student ID in the array
    	la $t2, studentId
    	li $t3, 0   				# Index

search_loop:
    	lw $t4, 0($t2)
    	beq $t4, $t1, update_status_dropoff     # Match found, go to update_status_dropoff
    	addiu $t2, $t2, 4   			# Move to the next student id
    	addiu $t3, $t3, 1   			# Increment the index
    	bne $t3, 5, search_loop   		# Continue searching until all students are checked

    	j invalidIDDropOff			# If ID is invalid, then display then go to the invalidIDDropOff procedure
 
 # Update student status to "Present"
update_status_dropoff:
    	
    	la $a0, name				# Show student name
    	jal printMsg
    
    	mul $t2, $t3, 4     			# Get offset to studentName item
    	la $t5, studentName			# Load the address of the student name
    	add $t2, $t2, $t5
    	move $a0, $t2				# Store in $t2
    	syscall

    	la $a0, studentAttend			# Display message to tell students are being dropped off
    	jal printMsg

    	# Update the status to "1" (Present)
    	li $v0, 1
    	mul $t2, $t3, 4     		# Get offset to student_status item
    	la $t5, studentStatus		# Load student status to update the database
    	add $t2, $t2, $t5
    	sw $v0, 0($t2)			# Store the address of $v0 in $t2	

    	j timeConfirmation
   
# Display message to tell that the student ID is invalid
invalidIDDropOff:
	
	la $a0, invalidIDMsg
	jal printMsg
	j loopConfirmationDropOff	# If invalid ID, then ask the user to choose whether to continue loop or not	

# If it's 8:30 A.M, then the drop off feature is going to exit
timeConfirmation:
	# Check if it's past 8:30 A.M. or not
	la $a0, timeMsg			# Display the message
	jal printMsg
	
	li $v0, 5
	syscall
	move $t1, $v0			# Store user input in $t1 for the if else condition
	
	# If >8:30, then system will exit 
	beq $t1, 0, loopConfirmationDropOff
	beq $t1, 1, exit

# User confirmation whether to continue loop or to use another feature	
loopConfirmationDropOff:
	
	la $a0, validationDropOff	# Display message to ask user the question
	jal printMsg
	
	li $v0, 5			# User choose 1 to go to main, 2 to go to dropOff again
	syscall
	move $t1, $v0			# Store user input in $t1 for the if else condition
	
	# Input 1 to go to main loop, Input 2 to go to Drop Off feature
	beq $t1, 1, main
	beq $t1, 2, dropOff

# Pick Up Feature
pickUp:
	# Pick Up Feature
	la $a0, pickUpMsg              # Display Pick Up message
	jal printMsg
	
	la $a0, carPresence            # Display car presence to pick up message
	jal printMsg
	
	la $a0, trafficVehicles	       # Display how many vehicles within the area
	jal printMsg
	
# Random number generator			
	li $v0, 42		      # Syscall to generate random number to randomize number of cars in the school area
	li $a1, 20		      # Only until 20 because school area is packed and small
	syscall
	move $s1, $a0
	
	# Print out the number of cars with pointing to $s1
	li $v0, 1
	la $a0, 0($s1)
	syscall
	
	la $a0, newline
	jal printMsg
	
	la $a0, nearestCarDistance	# GPS telling the nearest car from school
	jal printMsg
	
	li $v0, 5			# Ask user to choose pick up or drop off feature
	syscall
	
	bge $t6, 11, pickUp		# If more than 10, then it will loop again
	sw $v0, time			# We are assuming that 1 meter = 1 minute
	
	la $a0, noPlate			# Display message about plate number
	jal printMsg
	
   	#Read input from sensor (car plate number)
    	li $v0, 8            			# To read the plate number string
    	la $a0, plate_no     			
    	li $a1, 8            			# Only 8 as maximum because Malaysians usually have 7 character
    	syscall
    
    	# Determine the length of the detected plate number dynamically
    	la $t2, plate_no     			# Load the address of the detected plate
    	li $t3, 0            			# Initialize the length counter to 0

detect_length_loop_pickup:
    	lb $t4, 0($t2)        			# Load a character from the detected plate
    	beqz $t4, check_plate_pickup	 	# If the character is zero, end of string is reached
    	addi $t2, $t2, 1      			# Move to the next character in the detected plate
    	addi $t3, $t3, 1      			# Increment the length counter
    	j detect_length_loop_pickup  		# Check the next character
    
check_plate_pickup:
    # Check if the plate number detected exists in the school database
    	la $t1, registered_plates		# Load the address of the registered plates
    	la $t2, plate_no			# Load the address of the detected plate
    
compare_database_pickup:
    	lb $t3, 0($t1)				# Load a character from the registered plates from the database
    	beqz $t3, registeredVehiclePickup	# If the character is zero, end of list is reached
  
    	lb $t4, 0($t2)				# Load a character from the detected plate
    	bne $t3, $t4, not_matched_pickup	# If the characters do not match, branch to not_matched
    
    	addi $t2, $t2, 1
    	addi $t1, $t1, 1			# Increment counter to move to next character in the registered plates
    	j compare_database_pickup			# Check the next character

# Check if the entire plate has been compared
not_matched_pickup:
    
    	beqz $t4, registeredVehiclePickup		# If the character is zero, the entire detected plate has been matched
    	j unregisteredVehiclePickup			# Otherwise, branch to not_registered	

# Display Message telling the vehicles are registered	
registeredVehiclePickup: 
	
	la $a0, registeredMessage
	jal printMsg
	
	j notifyStaff

# Display Message telling the vehicles are unregistered	
unregisteredVehiclePickup:
	
	la $a0, unregisteredMessage
	jal printMsg
	
	j pickUp

# Popup notification on the app for staff/teachers
notifyStaff:
	la $a0, notifyMessage
	jal printMsg
	
	la $a0, newline
	jal printMsg
	
	la $a0, carInfo
	jal printMsg
	
	la $a0, noPlate
	jal printMsg
	
	la $a0, registered_plates
	jal printMsg
	
	la $a0, eta
	jal printMsg
	
	li $v0, 1
	lw $a0, time
	syscall
	
	la $a0, studentID
    	jal printMsg
    	
    	# Get the student ID from the user
    	li $v0, 5
    	syscall
    	move $t1, $v0   # Save the student ID

    	# Search for the student ID in the array
    	la $t2, studentId
    	li $t3, 0   				# Index

search_loop_pickup:
    	lw $t4, 0($t2)
    	beq $t4, $t1, update_status_pickup     # Match found, go to update_status_dropoff
    	addiu $t2, $t2, 4   			# Move to the next student id
    	addiu $t3, $t3, 1   			# Increment the index
    	bne $t3, 5, search_loop   		# Continue searching until all students are checked

    	# If ID is invalid, then display then go to the invalidID procedure
    	j invalidIDPickUp
    	
 # Update student status to "Present"
update_status_pickup:

    # Show student name
    li $v0, 4
    la $a0, name
    syscall
    mul $t2, $t3, 4     # Get offset to studentName item
    la $t5, studentName
    add $t2, $t2, $t5
    move $a0, $t2
    syscall
    
    la $a0, newline
    jal printMsg

    mul $t2, $t3, 4     # Get offset to studentStatus item
    la $t5, studentStatus
    add $t2, $t2, $t5
    lw $v0, 0($t2)   # Load the status

    # Update the status to "2" (Picked Up)
    li $v0, 2
    sw $v0, 0($t2)
    
    j scanID

# Prompt to remind student to scan the nametag	
scanID: 
		
	la $a0, newline
	jal printMsg
	
	la $a0, scanRfidPickUp
	jal printMsg
	
	la $a0, studentName
	jal printMsg
	
	la $a0, returnMsg
	jal printMsg

# Check if most student have gone back home or not
studentConfirmation:
	
	la $a0, studentStatusMsg	# Display the message
	jal printMsg
	
	li $v0, 5
	syscall
	move $t1, $v0			# Store user input in $t1 for the if else condition
	
	# If Majority have went back home, then system will exit 
	beq $t1, 0, loopConfirmationPickUp
	beq $t1, 1, exit

loopConfirmationPickUp:
	la $a0, validationPickUp	# Display message to ask user the question
	jal printMsg
	
	li $v0, 5			# User choose 1 to go to main, 2 to go to dropOff again,
	syscall
	move $t1, $v0			# Store user input in $t1 for the if else condition
	
	# Input 1 to go to main loop, Input 2 to go to Drop Off feature, Input 3 to exit the program
	beq $t1, 1, main
	beq $t1, 2, pickUp

# Display invalid ID for Pick Up
invalidIDPickUp:
	la $a0, invalidIDMsg
	jal printMsg	
	j notifyStaff

# Exit program	
exit:
	
	la $a0, exitMsg			#print exit program message
	jal printMsg
	
    	li $v0, 10         		# Load the exit syscall code
    	syscall           		# Exit the program	

# Procedure to print all the messages
printMsg:
	
	li $v0, 4
	syscall
	jr $ra





