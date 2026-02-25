import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminFaqPage extends StatelessWidget {
  const AdminFaqPage({super.key});

  @override
  Widget build(BuildContext context) {
    final CollectionReference faqsRef =
        FirebaseFirestore.instance.collection('faq');

    return Scaffold(
      appBar: AppBar(
        title: Center(
            child: const Text('Manage FAQs',
                style: TextStyle(color: Colors.black, fontSize: 20))),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: faqsRef.orderBy('question').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading FAQs'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          // return ListView.builder(
          //   itemCount: docs.length,
          //   itemBuilder: (context, i) {
          //     final doc = docs[i];
          //     return Card(
          //       margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          //       elevation: 2,
          //       child: ListTile(
          //         title: Text(doc['question']),
          //         subtitle: Text(doc['answer']),
          //         trailing: Row(
          //           mainAxisSize: MainAxisSize.min,
          //           children: [
          //             IconButton(
          //               icon: const Icon(Icons.edit, color: Colors.orange),
          //               onPressed: () {
          //                 _showEditDialog(context, faqsRef, doc);
          //               },
          //             ),
          //             IconButton(
          //               icon: const Icon(Icons.delete, color: Colors.red),
          //               onPressed: () {
          //                 faqsRef.doc(doc.id).delete();
          //               },
          //             ),
          //           ],
          //         ),
          //       ),
          //     );
          //   },
          // );
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc = docs[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 2,
                child: ListTile(
                  title: Text('${i + 1}. ${doc['question']}'),
                  subtitle: Text(doc['answer']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () {
                          _showEditDialog(context, faqsRef, doc);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          faqsRef.doc(doc.id).delete();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
        onPressed: () {
          _showAddDialog(context, faqsRef);
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context, CollectionReference faqsRef) {
    final questionCtrl = TextEditingController();
    final answerCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Add New FAQ'),
        content: SingleChildScrollView(
          child: Container(
            width: double.maxFinite,
            child: Column(
              children: [
                TextField(
                  controller: questionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Question',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: answerCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Answer',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final q = questionCtrl.text.trim();
              final a = answerCtrl.text.trim();
              if (q.isNotEmpty && a.isNotEmpty) {
                faqsRef.add({'question': q, 'answer': a});
                Navigator.pop(c);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, CollectionReference faqsRef,
      QueryDocumentSnapshot doc) {
    final qCtrl = TextEditingController(text: doc['question']);
    final aCtrl = TextEditingController(text: doc['answer']);

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Edit FAQ'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: qCtrl,
                decoration: const InputDecoration(
                  labelText: 'Question',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: aCtrl,
                decoration: const InputDecoration(
                  labelText: 'Answer',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final q = qCtrl.text.trim();
              final a = aCtrl.text.trim();
              if (q.isNotEmpty && a.isNotEmpty) {
                faqsRef.doc(doc.id).update({'question': q, 'answer': a});
                Navigator.pop(c);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
