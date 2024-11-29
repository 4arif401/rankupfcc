import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Challenge1Page extends StatelessWidget {
  Future<List<Map<String, dynamic>>> _fetchChallenges() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('Challenges').get();
    return snapshot.docs
        .map((doc) => {
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id, // Include the document ID
            })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Available Challenges'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchChallenges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No challenges available.'));
          }
          final challenges = snapshot.data!;
          return ListView.builder(
            itemCount: challenges.length,
            itemBuilder: (context, index) {
              final challenge = challenges[index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                child: ListTile(
                  title: Text(challenge['title']),
                  subtitle: Text(
                      '${challenge['description']}\nRequirement: ${challenge['requirement']} km\nReward: ${challenge['reward']} EXP'),
                  isThreeLine: true,
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, challenge); // Pass selected challenge back
                    },
                    child: Text('Accept'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
