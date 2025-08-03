import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// INFORMAÇÕES DA SUA PLANILHA - JÁ CONFIGURADAS
const String spreadsheetId = '1KymgU-oUhD2-LfqFjYbnAxsqCL1lKBnTV0n4mQYtiHU';
const String estoqueGid = '592944566';
const String pedidosGid = '1123391624';
const String ceimspaGid = '1537659950';
const String previsaoGid = '0';
// GID DA NOVA ABA 'lisde'
const String lisdeGid = '1943987384'; 

void main() {
  runApp(const LogisticsApp());
}

class LogisticsApp extends StatelessWidget {
  const LogisticsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PPU Digital',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue.shade900),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Lista de telas com os parâmetros corretos para cada busca
  static final List<Widget> _widgetOptions = <Widget>[
    SearchPage(
      searchType: SearchType.estoque,
      appBarTitle: 'Consulta de Estoque',
      searchHintText: 'Digite o Part Number...',
      disclaimerText: 'Esta consulta é meramente especulativa, consulte a LOC antes de tomar uma decisão.',
    ),
    SearchPage(
      searchType: SearchType.pedidos,
      appBarTitle: 'Consulta de Pedidos',
      searchHintText: 'Digite o Part Number...',
    ),
    SearchPage(
      searchType: SearchType.ceimspa,
      appBarTitle: 'Consulta CeIMSPA',
      searchHintText: 'Digite o PI...',
      disclaimerText: 'Esta consulta é meramente especulativa, consulte o Centro de Intendência.',
    ),
    SearchPage(
      searchType: SearchType.previsao,
      appBarTitle: 'Previsão de Entrega',
      searchHintText: 'Digite o Part Number...',
      disclaimerText: 'Esta consulta é meramente especulativa, consulte o DE para uma Data mais precisa.',
    ),
    // NOVO BOTÃO E TELA
    SearchPage(
      searchType: SearchType.lisde,
      appBarTitle: 'Consulta LISDE',
      searchHintText: 'Digite o Part Number...',
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/brasao.png'),
          fit: BoxFit.contain,
          colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, 
        body: Center(
          child: _widgetOptions.elementAt(_selectedIndex),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Estoque'),
            BottomNavigationBarItem(icon: Icon(Icons.local_shipping_outlined), label: 'Pedidos'),
            BottomNavigationBarItem(icon: Icon(Icons.factory_outlined), label: 'CeIMSPA'),
            BottomNavigationBarItem(icon: Icon(Icons.event_available_outlined), label: 'Previsão'),
            // NOVO BOTÃO
            BottomNavigationBarItem(icon: Icon(Icons.list_alt_outlined), label: 'LISDE'),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.amber[800],
          unselectedItemColor: Colors.grey[300],
          backgroundColor: Colors.black.withAlpha(204),
          type: BottomNavigationBarType.fixed,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}

// Enum para identificar o tipo de busca
enum SearchType { estoque, pedidos, ceimspa, previsao, lisde }

class SearchPage extends StatefulWidget {
  final SearchType searchType;
  final String appBarTitle;
  final String searchHintText;
  final String? disclaimerText;

  const SearchPage({
    super.key,
    required this.searchType,
    required this.appBarTitle,
    required this.searchHintText,
    this.disclaimerText,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  Widget _resultWidget = const SizedBox.shrink();
  bool _isLoading = false;

  // Função para buscar e processar os dados da planilha
  Future<void> _performSearch() async {
    if (_controller.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _resultWidget = const SizedBox.shrink();
    });

    String gid;
    String searchColumn;
    switch (widget.searchType) {
      case SearchType.estoque:
        gid = estoqueGid;
        searchColumn = 'part_number';
        break;
      case SearchType.pedidos:
        gid = pedidosGid;
        searchColumn = 'part_number';
        break;
      case SearchType.ceimspa:
        gid = ceimspaGid;
        searchColumn = 'pi';
        break;
      case SearchType.previsao:
        gid = previsaoGid;
        searchColumn = 'part_number';
        break;
      case SearchType.lisde:
        gid = lisdeGid;
        searchColumn = 'part_number';
        break;
    }

    final url = 'https://docs.google.com/spreadsheets/d/$spreadsheetId/export?format=csv&gid=$gid';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<Map<String, String>> results = _parseCsv(response.body, _controller.text, searchColumn);
        _resultWidget = _buildResultWidget(results);
      } else {
        _resultWidget = const ResultCard(lines: ['Erro ao buscar dados.']);
      }
    } catch (e) {
      _resultWidget = const ResultCard(lines: ['Erro de conexão. Verifique a internet.']);
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Converte o texto CSV em uma lista de objetos
  List<Map<String, String>> _parseCsv(String csvText, String query, String searchColumn) {
    final lines = const LineSplitter().convert(csvText);
    if (lines.isEmpty) return [];

    final headers = lines.first.split(',');
    final searchColumnIndex = headers.indexOf(searchColumn);
    if (searchColumnIndex == -1) return [];

    List<Map<String, String>> results = [];
    for (var i = 1; i < lines.length; i++) {
      final values = lines[i].split(',');
      if (values.length > searchColumnIndex && values[searchColumnIndex].trim().toLowerCase() == query.trim().toLowerCase()) {
        Map<String, String> row = {};
        for (var j = 0; j < headers.length; j++) {
          row[headers[j].trim()] = values.length > j ? values[j].trim() : '';
        }
        results.add(row);
      }
    }
    return results;
  }

  // Constrói o widget de resultado com base nos dados encontrados
  Widget _buildResultWidget(List<Map<String, String>> results) {
    if (results.isEmpty) {
      String message;
      switch (widget.searchType) {
        case SearchType.estoque: message = 'Não há em estoque'; break;
        case SearchType.pedidos: message = 'Não há SE-PD Ativa para este Item'; break;
        case SearchType.ceimspa: message = 'Provavelmente esse item não tenha no CeIMSPA'; break;
        case SearchType.previsao: message = 'Ainda não há previsão de entrega pra este item'; break;
        case SearchType.lisde: message = 'Este item não é contemplado pela LISDE'; break;
      }
      return ResultCard(lines: [message]);
    }

    List<String> lines = [];
    switch (widget.searchType) {
      case SearchType.estoque:
        lines.add('Part Number: ${results.first['part_number']}');
        lines.add('Nomenclatura: ${results.first['nomenclatura']}'); // CAMPO ADICIONADO
        lines.add('---');
        for (var item in results) {
          lines.add('Localização (LOC): ${item['loc']}');
          lines.add('Quantidade: ${item['quantidade']}');
          lines.add('---');
        }
        break;
      case SearchType.pedidos:
        for (var i = 0; i < results.length; i++) {
          var item = results[i];
          lines.add('SE-PD: ${item['sepd']}');
          lines.add('Part Number: ${item['part_number']}');
          lines.add('Status: ${item['status']}');
          lines.add('Nº da OC: ${item['oc']}');
          lines.add('Quantidade: ${item['quantidade']}');
          lines.add('Valor USD: \$${item['valor_usd']}');
          if (i < results.length - 1) lines.add('---');
        }
        break;
      case SearchType.ceimspa:
        lines.add('PI: ${results.first['pi']}');
        lines.add('Nomenclatura: ${results.first['nomenclatura']}'); // CAMPO ADICIONADO
        lines.add('Quantidade: ${results.first['quantidade']}');
        break;
      case SearchType.previsao:
         lines.add('Part Number: ${results.first['part_number']}');
         lines.add('Quantidade a chegar: ${results.first['quantidade']}'); // CAMPO ADICIONADO
         lines.add('Possível data de entrega: ${results.first['data_entrega']}');
        break;
      case SearchType.lisde:
        lines.add('Part Number: ${results.first['part_number']}');
        lines.add('Nomenclatura: ${results.first['nomenclatura']}');
        lines.add('Quantidade: ${results.first['quantidade']}');
        break;
    }
    return ResultCard(lines: lines);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Center(child: AppHeader()),
        backgroundColor: Colors.black,
        elevation: 0,
        toolbarHeight: 110,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(widget.appBarTitle, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w500)),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: widget.searchHintText,
                hintStyle: TextStyle(color: Colors.grey[300]),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.black.withAlpha(102),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none),
              ),
              onSubmitted: (value) => _performSearch(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _performSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[700],
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.black)) : const Text('Buscar'),
            ),
            const SizedBox(height: 24),
            Expanded(child: SingleChildScrollView(child: _resultWidget)),
            if (widget.disclaimerText != null)
              Container(
                margin: const EdgeInsets.only(top: 16.0),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Colors.white.withAlpha(230), borderRadius: BorderRadius.circular(8)),
                child: Text(widget.disclaimerText!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }
}

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('MARINHA DO BRASIL', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
        Text('1º Esqd. de Helicópteros de Esclarecimento e Ataque (HA-1)', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        Text('Paiol de Pronto Uso (PPU)', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text('PPU DIGITAL', style: TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      ],
    );
  }
}

class ResultCard extends StatelessWidget {
  final List<String> lines;
  const ResultCard({super.key, required this.lines});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black.withAlpha(178),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: lines.map((line) => Text(line, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5))).toList(),
        ),
      ),
    );
  }
}
