import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FaqView extends StatelessWidget {
  const FaqView({super.key});

  @override
  Widget build(BuildContext context) {
    final CollectionReference faqRef =
        FirebaseFirestore.instance.collection('faq');

    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQ'),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(color: Colors.black, fontSize: 20),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: faqRef.orderBy('question').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Failed to load FAQs'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('No FAQs found.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final question = doc['question'];
              final answer = doc['answer'];

              return ExpansionTile(
                title: Text(question,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(answer),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
