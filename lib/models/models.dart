class User {
  final int? id;
  final String name;
  final String email;
  final String password; // Add this field
  final String preferences;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.preferences,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password, // Ensure this field is added
      'preferences': preferences,
    };
  }

  static User fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      password: map['password'], // Ensure this field is mapped
      preferences: map['preferences'],
    );
  }
}

class Event {
  final int? id; // SQLite ID
  final String name;
  final String date;
  final String location;
  final String description;
  final int userId;
  final int? friendId; // Add this field to associate events with friends
  List<Gift> gifts;

  Event({
    this.id,
    required this.name,
    required this.date,
    required this.location,
    required this.description,
    required this.userId,
    this.friendId,
    this.gifts = const [],
  });

  // Convert Event to a Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'date': date,
      'location': location,
      'description': description,
      'userId': userId,
      'friendId': friendId, // Include friendId in the Map
    };
  }

  // Create Event object from a Map
  static Event fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      name: map['name'],
      date: map['date'],
      location: map['location'],
      description: map['description'],
      userId: map['userId'],
      friendId: map['friendId'], // Map the friendId field
    );
  }
}



class Gift {
  final int? id; // Primary key
  final String name;
  final String description;
  final String category;
  final double price;
  final String status;
  final int eventId; // Foreign key referencing events
  final int? friendId; // Foreign key referencing friends

  Gift({
    this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.status,
    required this.eventId,
    this.friendId, // Make this nullable to allow gifts without friend association
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'status': status,
      'eventId': eventId,
      'friendId': friendId, // Add friendId to the map
    };
  }

  static Gift fromMap(Map<String, dynamic> map) {
    return Gift(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      category: map['category'],
      price: map['price'],
      status: map['status'],
      eventId: map['eventId'],
      friendId: map['friendId'], // Map the friendId field
    );
  }
}

class Friend {
  final int userId;
  final int friendId;

  Friend({required this.userId, required this.friendId});

  Map<String, dynamic> toMap() {
    return {'userId': userId, 'friendId': friendId};
  }

  static Friend fromMap(Map<String, dynamic> map) {
    return Friend(
      userId: map['userId'],
      friendId: map['friendId'],
    );
  }
}
