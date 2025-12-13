/**
 * Database Seeder
 * Creates sample data for testing
 * Run with: npm run seed
 */

require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const config = require('../config');

// Import models
const { User, Ride, Booking, Review, Notification } = require('../models');

// Sample data
const users = [
  {
    name: 'Ahmed Al-Khalifa',
    email: 'ahmed.khalifa@aubh.edu.bh',
    universityId: '202100001',
    password: 'Password123!',
    phoneNumber: '+97333001001',
    gender: 'male',
    isEmailVerified: true,
    isDriver: true,
    carDetails: {
      model: 'Toyota Camry 2022',
      color: 'Silver',
      licensePlate: 'ABC1234',
      totalSeats: 4
    }
  },
  {
    name: 'Fatima Hassan',
    email: 'fatima.hassan@aubh.edu.bh',
    universityId: '202100002',
    password: 'Password123!',
    phoneNumber: '+97333002002',
    gender: 'female',
    isEmailVerified: true,
    isDriver: true,
    carDetails: {
      model: 'Honda Accord 2021',
      color: 'White',
      licensePlate: 'XYZ5678',
      totalSeats: 4
    }
  },
  {
    name: 'Mohammed Yusuf',
    email: 'mohammed.yusuf@aubh.edu.bh',
    universityId: '202100003',
    password: 'Password123!',
    phoneNumber: '+97333003003',
    gender: 'male',
    isEmailVerified: true,
    isDriver: false
  },
  {
    name: 'Sara Ahmed',
    email: 'sara.ahmed@aubh.edu.bh',
    universityId: '202100004',
    password: 'Password123!',
    phoneNumber: '+97333004004',
    gender: 'female',
    isEmailVerified: true,
    isDriver: false
  },
  {
    name: 'Ali Ibrahim',
    email: 'ali.ibrahim@aubh.edu.bh',
    universityId: '202100005',
    password: 'Password123!',
    phoneNumber: '+97333005005',
    gender: 'male',
    isEmailVerified: true,
    isDriver: true,
    carDetails: {
      model: 'Nissan Altima 2023',
      color: 'Black',
      licensePlate: 'DEF9012',
      totalSeats: 4
    }
  }
];

// Bahrain locations with real coordinates
const locations = [
  {
    name: 'AUBH Campus',
    address: 'American University of Bahrain, Riffa',
    coordinates: { lat: 26.1300, lng: 50.5500 } // AUBH Campus, Riffa
  },
  {
    name: 'Riffa Views',
    address: 'Riffa Views, Bahrain',
    coordinates: { lat: 26.1250, lng: 50.5550 } // Riffa Views residential area
  },
  {
    name: 'Seef Mall',
    address: 'Seef District, Manama',
    coordinates: { lat: 26.2381, lng: 50.5481 } // Seef Mall, Seef District
  },
  {
    name: 'Bahrain City Centre',
    address: 'Bahrain City Centre, Manama',
    coordinates: { lat: 26.2189, lng: 50.5822 } // Bahrain City Centre Mall
  },
  {
    name: 'Juffair',
    address: 'Juffair, Manama',
    coordinates: { lat: 26.2100, lng: 50.6000 } // Juffair district
  },
  {
    name: 'Muharraq',
    address: 'Muharraq, Bahrain',
    coordinates: { lat: 26.2578, lng: 50.6117 } // Muharraq city center
  },
  {
    name: 'Adliya',
    address: 'Adliya, Manama',
    coordinates: { lat: 26.2200, lng: 50.5700 } // Adliya district
  },
  {
    name: 'Budaiya',
    address: 'Budaiya, Bahrain',
    coordinates: { lat: 26.2050, lng: 50.4500 } // Budaiya area
  },
  {
    name: 'Isa Town',
    address: 'Isa Town, Bahrain',
    coordinates: { lat: 26.1736, lng: 50.5478 } // Isa Town
  },
  {
    name: 'Sitra',
    address: 'Sitra, Bahrain',
    coordinates: { lat: 26.1550, lng: 50.6200 } // Sitra industrial area
  }
];

// Helper to get random future date
const getRandomFutureDate = (daysAhead = 7) => {
  const now = new Date();
  const randomDays = Math.floor(Math.random() * daysAhead) + 1;
  const randomHours = Math.floor(Math.random() * 12) + 7; // 7 AM to 7 PM
  const date = new Date(now);
  date.setDate(date.getDate() + randomDays);
  date.setHours(randomHours, 0, 0, 0);
  return date;
};

// Seeder function
const seedDatabase = async () => {
  try {
    // Connect to database
    await mongoose.connect(config.mongodbUri);
    console.log('Connected to MongoDB');

    // Clear existing data
    console.log('Clearing existing data...');
    await User.deleteMany({});
    await Ride.deleteMany({});
    await Booking.deleteMany({});
    await Review.deleteMany({});
    await Notification.deleteMany({});

    // Create users
    console.log('Creating users...');
    const createdUsers = [];
    for (const userData of users) {
      const user = await User.create(userData);
      createdUsers.push(user);
      console.log(`  Created user: ${user.name}`);
    }

    // Create rides
    console.log('Creating rides...');
    const rides = [];
    const drivers = createdUsers.filter(u => u.isDriver);

    for (const driver of drivers) {
      // Create 2-3 rides per driver
      const numRides = Math.floor(Math.random() * 2) + 2;
      
      for (let i = 0; i < numRides; i++) {
        const startIdx = Math.floor(Math.random() * locations.length);
        let endIdx = Math.floor(Math.random() * locations.length);
        while (endIdx === startIdx) {
          endIdx = Math.floor(Math.random() * locations.length);
        }

        const ride = await Ride.create({
          driver: driver._id,
          startLocation: {
            address: locations[startIdx].address,
            coordinates: locations[startIdx].coordinates
          },
          destination: {
            address: locations[endIdx].address,
            coordinates: locations[endIdx].coordinates
          },
          route: {
            distance: Math.floor(Math.random() * 20000) + 5000, // 5-25 km
            duration: Math.floor(Math.random() * 1800) + 600 // 10-40 min
          },
          departureTime: getRandomFutureDate(),
          totalSeats: driver.carDetails.totalSeats,
          availableSeats: driver.carDetails.totalSeats,
          pricePerSeat: 0, // Will be calculated after completion
          genderPreference: ['any', 'any', 'male', 'female'][Math.floor(Math.random() * 4)]
        });

        rides.push(ride);
        console.log(`  Created ride: ${locations[startIdx].name} → ${locations[endIdx].name}`);
      }
    }

    // Create some bookings
    console.log('Creating bookings...');
    const passengers = createdUsers.filter(u => !u.isDriver);
    
    for (const passenger of passengers) {
      // Book 1-2 rides per passenger
      const availableRides = rides.filter(r => 
        r.driver.toString() !== passenger._id.toString() && 
        r.availableSeats > 0
      );

      if (availableRides.length > 0) {
        const ride = availableRides[Math.floor(Math.random() * availableRides.length)];
        
        // Generate safe codes
        const generateSafeCode = () => {
          return Math.floor(1000 + Math.random() * 9000).toString(); // 4-digit code
        };
        const riderSafeCode = generateSafeCode();
        const driverSafeCode = generateSafeCode();

        const booking = await Booking.create({
          ride: ride._id,
          passenger: passenger._id,
          seatsBooked: 1,
          totalAmount: 0, // Will be calculated after completion
          riderSafeCode,
          driverSafeCode,
          status: 'pending', // Start as pending to test acceptance flow
          // Don't set confirmedAt - let it be set when driver accepts
        });

        // Don't decrement seats here - seats are only decremented when booking is accepted
        // Remove: ride.availableSeats -= 1;
        // Remove: await ride.save();

        console.log(`  Created booking for ${passenger.name}`);
      }
    }

    // Create welcome notifications
    console.log('Creating notifications...');
    for (const user of createdUsers) {
      await Notification.createNotification('system_announcement', user._id, {
        title: 'Welcome to UniRide!',
        message: 'Start sharing rides with fellow AUBH students today.'
      });
    }

    console.log('\n✅ Database seeded successfully!');
    console.log('\nTest Accounts:');
    console.log('─'.repeat(50));
    for (const user of users) {
      console.log(`Email: ${user.email}`);
      console.log(`Password: ${user.password}`);
      console.log(`Driver: ${user.isDriver ? 'Yes' : 'No'}`);
      console.log('─'.repeat(50));
    }

    process.exit(0);
  } catch (error) {
    console.error('Seeding error:', error);
    process.exit(1);
  }
};

// Run seeder
seedDatabase();
