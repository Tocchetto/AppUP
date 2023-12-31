import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unidade Popular pelo Socialismo',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Unidade Popular pelo Socialismo'),
          backgroundColor: Colors.black,
        ),
        body: FutureBuilder<List<Evento>>(
          future: fetchEvents(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Erro: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Nenhum evento encontrado'));
            } else {
              var eventosPorData = agruparEventosPorData(snapshot.data!);
              return ListView(
                children: eventosPorData.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat('dd/MM/yyyy').format(entry.key)), // Mostra a data
                      ...entry.value.map((evento) {
                        return ListTile(
                            title: Text(evento.titulo),
                            subtitle: Text(evento.descricao)
                        );
                      }).toList(),
                    ],
                  );
                }).toList(),
              );
            }
          },
        ),
      ),
    );
  }
}

Future<List<Evento>> fetchEvents() async {
  final calendarId = 'c3de1c8f61a43c212e13746e43f55c94e0a5311557d34eedcb3a7651226a7dc3@group.calendar.google.com';
  final apiKey = await rootBundle.loadString('config/calendar_key.txt');
  final url = Uri.parse('https://www.googleapis.com/calendar/v3/calendars/$calendarId/events?key=$apiKey');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    var data = json.decode(response.body);
    var items = data['items'] as List; // Obtém a lista de eventos
    List<Evento> eventos = items.map((item) {
      return Evento.fromJson(item);
    }).toList();

    return eventos;
  } else {
    throw Exception('Falha na requisição: ${response.statusCode} Resposta: ${response.body} Falha ao carregar eventos');
  }
}

Map<DateTime, List<Evento>> agruparEventosPorData(List<Evento> eventos) {
  Map<DateTime, List<Evento>> eventosPorData = {};
  for (var evento in eventos) {
    // Obter apenas a data, ignorando a hora
    var dataEvento = DateTime(evento.data.year, evento.data.month, evento.data.day);
    if (eventosPorData.containsKey(dataEvento)) {
      eventosPorData[dataEvento]!.add(evento);
    } else {
      eventosPorData[dataEvento] = [evento];
    }
  }
  return eventosPorData;
}


class Evento {
  String titulo;
  String descricao;
  DateTime data; // Adicione um campo para a data do evento

  Evento({required this.titulo, required this.descricao, required this.data});

  factory Evento.fromJson(Map<String, dynamic> json) {
    return Evento(
      titulo: json['summary'] ?? 'Sem título',
      descricao: json['description'] ?? 'Sem descrição',
      data: DateTime.parse(json['start']['dateTime'] ?? json['start']['date']), // Adapte conforme o formato da sua API
    );
  }
}
