# Requirements

## Functional Requirements

**User Account and Authentication:**  
The system must allow users to register with a registered university email, verifying with ID before granting access. It will also support secure login and logout functionality where data will be encrypted and never stored as plain text.  

**Ride Posting and Management:**  
A driver must be able to create a new ride by entering destination, route, date and time, and seat availability. The system must then store the details and display them to other users while still allowing the driver to update or cancel the posted ride.  

**Ride Search and Booking:**  
A passenger must be able to search for available rides by start point, date and time, and destination. Displaying only rides with available seats and allowing customers to book one of those seats, reducing the available seat count in the system at the same time.  

**Ride Confirmation and Notifications:**  
The system must send confirmation to the user through the application or the registered email, ensuring constant updates regarding ride details and displaying them in a specified tab.  

**Ratings and Reviews:**  
The system must allow riders to rate and review drivers after the ride is complete, ensuring the reviews are shown on the drivers’ profile and not allow tampering after posting it.  

**In-App Messaging and Moderation:**  
The system must allow communication between drivers and riders within the application, ensuring user comfort by flagging both inappropriate terms and personal information being shared.  

**Dashboard Management:**  
The system must provide a dashboard for each user that displays options such as posting a ride, viewing available rides, managing user profiles, and seeing relevant statistics.  

**Proximity System:**  
The system must integrate location services that display current location and proximity between riders and drivers in real time. This ensures that drivers use the most efficient routes while riders only pick nearby rides.  

**Cost Calculation and Splitting:**  
The system must automatically calculate and split the cost of the ride among all passengers, ensuring that every rider pays according to their part in the ride. This cost must also be displayed clearly to users.  

**Ride History:**  
The system has to allow users to view details of past rides like the driver or basic information of other riders, as well as basic analytics like cost, ratings, route taken, and even money saved.  

---

## Non-Functional Requirements

**Performance:**  
The application should show search results within a few seconds and be able to handle multiple concurrent users.  

**Security:**  
To ensure security, the system should transmit all data over HTTPS, encrypt passwords and sensitive data, and only allow verified university students to access the app.  

**Usability:**  
The interface should be easy to use and appealing to new users, where core features are easy to reach, and error messages are simplified.  

**Reliability:**  
The system should be accessible during active hours, have reliable data backups in case of a crash, and synchronize with the server as frequently as possible.  

**Scalability:**  
The code should be organized and easy to work with; this is to ensure that maintaining or adding new features will flow smoothly.

