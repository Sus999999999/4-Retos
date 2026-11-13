import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Cripto {
  final String id, nombre, simbolo, emoji;
  const Cripto(this.id, this.nombre, this.simbolo, this.emoji);
}

const kCriptos = [
  Cripto('bitcoin', 'Bitcoin', 'BTC', '₿'),
  Cripto('ethereum', 'Ethereum', 'ETH', 'Ξ'),
  Cripto('solana', 'Solana', 'SOL', '◎'),
];

/// Endpoint simple de CoinGecko (sin autenticación):
/// GET /simple/price?ids=bitcoin,ethereum,solana&vs_currencies=usd
Future<Map<String, double>> obtenerPrecios() async {
  final uri = Uri.https('api.coingecko.com', '/api/v3/simple/price', {
    'ids': kCriptos.map((c) => c.id).join(','),
    'vs_currencies': 'usd',
  });
  final resp = await http.get(uri).timeout(const Duration(seconds: 15));
  if (resp.statusCode == 429) {
    throw Exception('Demasiadas peticiones, espera un momento y reintenta');
  }
  if (resp.statusCode != 200) throw Exception('Error ${resp.statusCode}');
  final data = jsonDecode(resp.body) as Map<String, dynamic>;
  return {
    for (final c in kCriptos) c.id: (data[c.id]['usd'] as num).toDouble(),
  };
}

class Reto4Cripto extends StatefulWidget {
  const Reto4Cripto({super.key});

  @override
  State<Reto4Cripto> createState() => _Reto4CriptoState();
}

class _Reto4CriptoState extends State<Reto4Cripto> {
  late Future<Map<String, double>> _futuro;
  final _montoCtrl = TextEditingController(text: '100');

  @override
  void initState() {
    super.initState();
    _futuro = obtenerPrecios();
  }

  void _refrescar() => setState(() => _futuro = obtenerPrecios());

  double get _monto =>
      double.tryParse(_montoCtrl.text.replaceAll(',', '.')) ?? 0;

  String _fmtUsd(double v) {
    final partes = v.toStringAsFixed(2).split('.');
    final ent = partes[0].replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
    return '\$$ent.${partes[1]}';
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🪙 Convertidor Cripto'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refrescar),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _montoCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Monto en USD',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<Map<String, double>>(
                future: _futuro,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            snap.error.toString().replaceFirst('Exception: ', ''),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                              onPressed: _refrescar,
                              child: const Text('Reintentar')),
                        ],
                      ),
                    );
                  }
                  final precios = snap.data!;
                  return ListView.separated(
                    itemCount: kCriptos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final c = kCriptos[i];
                      final precio = precios[c.id]!;
                      final fraccion = precio == 0 ? 0 : _monto / precio;
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                              radius: 26,
                              child: Text(c.emoji,
                                  style: const TextStyle(fontSize: 22))),
                          title: Text('${c.nombre} (${c.simbolo})',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          subtitle: Text('Precio: ${_fmtUsd(precio)} USD'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(fraccion.toStringAsFixed(6),
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              Text(c.simbolo,
                                  style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
