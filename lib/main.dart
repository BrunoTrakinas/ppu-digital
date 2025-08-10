import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; // Pacote para guardar dados

// INFORMAÇÕES DA SUA PLANILHA - JÁ CONFIGURADAS
const String spreadsheetId = '1KymgU-oUhD2-LfqFjYbnAxsqCL1lKBnTV0n4mQYtiHU';
const String estoqueGid = '592944566';
const String pedidosGid = '1123391624';
const String ceimspaGid = '1537659950';
const String previsaoGid = '0';
const String lisdeGid = '1943987384'; 
const String ocGid = '54887043';
const String loginGid = '954993613';

// CORREÇÃO: Função movida para o topo para ser acessível globalmente.
List<String> _splitCsvLine(String line) {
  final List<String> fields = [];
  StringBuffer currentField = StringBuffer();
  bool inQuotes = false;
  for (int i = 0; i < line.length; i++) {
    final char = line[i];
    if (char == '"') {
      if (i + 1 < line.length && line[i + 1] == '"') {
        currentField.write('"');
        i++; 
      } else {
        inQuotes = !inQuotes;
      }
    } else if (char == ',' && !inQuotes) {
      fields.add(currentField.toString().trim());
      currentField.clear();
    } else {
      currentField.write(char);
    }
  }
  fields.add(currentField.toString().trim());
  return fields;
}

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
      home: const LoginPage(),
    );
  }
}

// TELA DE LOGIN ATUALIZADA
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _loginFailed = false;

  @override
  void initState() {
    super.initState();
    _loadEmail(); // Carrega o email guardado ao iniciar a tela
  }

  Future<void> _loadEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final String? email = prefs.getString('saved_email');
    if (email != null) {
      setState(() {
        _emailController.text = email;
      });
    }
  }

  Future<void> _saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_email', email);
  }

  Future<void> _attemptLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _loginFailed = false;
    });

    bool success = false;
    final url = 'https://docs.google.com/spreadsheets/d/$spreadsheetId/export?format=csv&gid=$loginGid';
    
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final String decodedBody = utf8.decode(response.bodyBytes);
        final bool credentialsValid = await _validateCredentials(decodedBody);
        if (credentialsValid) {
          await _saveEmail(_emailController.text);
          success = true;
        }
      }
    } catch (e) {
      // O erro será tratado pela UI, mostrando a mensagem de falha.
    }

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else {
      setState(() {
        _loginFailed = true;
        _isLoading = false;
      });
    }
  }

  Future<bool> _validateCredentials(String csvText) async {
    final lines = const LineSplitter().convert(csvText.replaceAll('\r', ''));
    if (lines.length < 2) return false;

    final headers = _splitCsvLine(lines.first);
    final emailIndex = headers.indexOf('email');
    final passwordIndex = headers.indexOf('senha');

    if (emailIndex == -1 || passwordIndex == -1) return false;

    for (var i = 1; i < lines.length; i++) {
      if (lines[i].isEmpty) continue;
      final values = _splitCsvLine(lines[i]);
      if (values.length > emailIndex && values.length > passwordIndex) {
        if (values[emailIndex].trim().toLowerCase() == _emailController.text.trim().toLowerCase() &&
            values[passwordIndex].trim() == _passwordController.text.trim()) {
          return true;
        }
      }
    }
    return false;
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
        appBar: AppBar(
          title: const Center(child: AppHeader()),
          backgroundColor: Colors.black,
          elevation: 0,
          toolbarHeight: 110,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_loginFailed) ...[
                  TextField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Email',
                      hintStyle: TextStyle(color: Colors.grey[300]),
                      prefixIcon: const Icon(Icons.email_outlined, color: Colors.white),
                      filled: true,
                      fillColor: Colors.black.withAlpha(102),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    style: const TextStyle(color: Colors.white),
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Senha',
                      hintStyle: TextStyle(color: Colors.grey[300]),
                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.white),
                      filled: true,
                      fillColor: Colors.black.withAlpha(102),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _attemptLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[700],
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.black))
                        : const Text('Logar', style: TextStyle(fontSize: 16)),
                  ),
                ] else ...[
                  // Tela de erro de login
                  const Text(
                    'Login ou senha incorretos. Por favor, entre em contato com o administrador.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _loginFailed = false;
                        _passwordController.clear();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    ),
                    child: const Text('Tentar Novamente', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
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

  static final List<Widget> _widgetOptions = <Widget>[
    SearchPage(
      searchType: SearchType.estoque,
      appBarTitle: 'Consulta de Estoque',
      searchHintText: 'Digite o Part Number ou PI...',
      disclaimerText: 'Esta consulta é meramente especulativa, consulte a LOC antes de tomar uma decisão.',
    ),
    SearchPage(
      searchType: SearchType.pedidos,
      appBarTitle: 'Consulta de Pedidos',
      searchHintText: 'Digite o Part Number...',
    ),
    SearchPage(
      searchType: SearchType.oc,
      appBarTitle: 'Consulta de OC',
      searchHintText: 'Digite o número da OC...',
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
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'OC'),
            BottomNavigationBarItem(icon: Icon(Icons.factory_outlined), label: 'CeIMSPA'),
            BottomNavigationBarItem(icon: Icon(Icons.event_available_outlined), label: 'Previsão'),
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

enum SearchType { estoque, pedidos, ceimspa, previsao, lisde, oc }
enum StockSearchMode { exact, radical }

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

  Future<void> _performSearch({StockSearchMode mode = StockSearchMode.exact}) async {
    if (_controller.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _resultWidget = const SizedBox.shrink();
    });

    Widget finalResult;
    String gid;
    List<String> searchColumns;
    StockSearchMode finalMode = (widget.searchType == SearchType.oc) ? StockSearchMode.radical : mode;

    switch (widget.searchType) {
      case SearchType.estoque:
        gid = estoqueGid;
        searchColumns = ['part_number', 'pi'];
        break;
      case SearchType.pedidos:
        gid = pedidosGid;
        searchColumns = ['part_number'];
        break;
      case SearchType.ceimspa:
        gid = ceimspaGid;
        searchColumns = ['pi'];
        break;
      case SearchType.previsao:
        gid = previsaoGid;
        searchColumns = ['part_number'];
        break;
      case SearchType.lisde:
        gid = lisdeGid;
        searchColumns = ['part_number'];
        break;
      case SearchType.oc:
        gid = ocGid;
        searchColumns = ['oc'];
        break;
    }

    final url = 'https://docs.google.com/spreadsheets/d/$spreadsheetId/export?format=csv&gid=$gid';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final String decodedBody = utf8.decode(response.bodyBytes);
        final List<Map<String, String>> results = _parseCsv(decodedBody, _controller.text, searchColumns, finalMode);
        finalResult = _buildResultWidget(results, finalMode);
      } else {
        finalResult = const ResultCard(lines: ['Erro ao buscar dados.']);
      }
    } catch (e) {
      finalResult = const ResultCard(lines: ['Erro de conexão. Verifique a internet.']);
    }

    if (!mounted) return;

    setState(() {
      _resultWidget = finalResult;
      _isLoading = false;
    });
  }

  List<Map<String, String>> _parseCsv(String csvText, String query, List<String> searchColumns, StockSearchMode mode) {
    final lines = const LineSplitter().convert(csvText.replaceAll('\r', ''));
    if (lines.length < 2) return [];

    final headers = _splitCsvLine(lines.first);
    
    List<Map<String, String>> results = [];
    final lowerCaseQuery = query.trim().toLowerCase();

    for (var i = 1; i < lines.length; i++) {
      if (lines[i].isEmpty) continue;

      final values = _splitCsvLine(lines[i]);
      
      Map<String, String> row = {};
      for (var j = 0; j < headers.length; j++) {
        row[headers[j]] = (j < values.length) ? values[j] : '';
      }

      bool foundMatch = false;
      for (final searchColumn in searchColumns) {
        final cellValue = (row[searchColumn] ?? '').toLowerCase();
        
        bool match = (mode == StockSearchMode.exact)
            ? cellValue == lowerCaseQuery
            : cellValue.startsWith(lowerCaseQuery);

        if (match) {
          foundMatch = true;
          break;
        }
      }
      
      if (foundMatch) {
        results.add(row);
      }
    }
    return results;
  }

  Widget _buildResultWidget(List<Map<String, String>> results, StockSearchMode mode) {
    if (results.isEmpty) {
      String message;
      switch (widget.searchType) {
        case SearchType.estoque: message = 'Não há em estoque'; break;
        case SearchType.pedidos: message = 'Não há SE-PD Ativa para este Item'; break;
        case SearchType.ceimspa: message = 'Provavelmente esse item não tenha no CeIMSPA'; break;
        case SearchType.previsao: message = 'Ainda não há previsão de entrega pra este item'; break;
        case SearchType.lisde: message = 'Este item não é contemplado pela LISDE'; break;
        case SearchType.oc: message = 'Nenhuma Ordem de Compra encontrada'; break;
      }
      return ResultCard(lines: [message]);
    }

    if (widget.searchType == SearchType.estoque) {
      Map<String, List<Map<String, String>>> groupedByPN = {};
      for (var result in results) {
        String pn = result['part_number'] ?? 'N/A';
        if (!groupedByPN.containsKey(pn)) {
          groupedByPN[pn] = [];
        }
        groupedByPN[pn]!.add(result);
      }

      List<Widget> resultWidgets = [];
      int colorIndex = 0;
      groupedByPN.forEach((pn, items) {
        List<String> lines = [];
        lines.add('Part Number: ${items.first['part_number']}');
        lines.add('PI: ${items.first['pi']}');
        lines.add('Nomenclatura: ${items.first['nomenclatura']}');
        lines.add('---');
        for (var item in items) {
          lines.add('Localização (LOC): ${item['loc']}');
          lines.add('Quantidade: ${item['quantidade']}');
          lines.add('---');
        }
        
        Color cardColor;
        Color textColor;
        if (mode == StockSearchMode.radical) {
          cardColor = colorIndex.isEven ? Colors.black.withAlpha(178) : Colors.grey[200]!;
          textColor = colorIndex.isEven ? Colors.white : Colors.black;
        } else {
          cardColor = Colors.black.withAlpha(178);
          textColor = Colors.white;
        }

        resultWidgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: ResultCard(
              lines: lines,
              backgroundColor: cardColor,
              textColor: textColor,
            ),
          )
        );
        colorIndex++;
      });
      return Column(children: resultWidgets);
    }
    
    List<String> lines = [];
    switch (widget.searchType) {
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
        lines.add('Nomenclatura: ${results.first['nomenclatura']}');
        lines.add('Quantidade: ${results.first['quantidade']}');
        break;
      case SearchType.previsao:
         lines.add('Part Number: ${results.first['part_number']}');
         lines.add('Quantidade a chegar: ${results.first['quantidade']}');
         lines.add('Possível data de entrega: ${results.first['data_entrega']}');
        break;
      case SearchType.lisde:
        lines.add('Part Number: ${results.first['part_number']}');
        lines.add('Nomenclatura: ${results.first['nomenclatura']}');
        lines.add('Quantidade: ${results.first['quantidade']}');
        break;
      case SearchType.oc:
        for (var i = 0; i < results.length; i++) {
          var item = results[i];
          lines.add('OC: ${item['oc']}');
          lines.add('Prioridade: ${item['prioridade']}');
          lines.add('Condição: ${item['condicao']}');
          lines.add('Valor USD: \$${item['valor_usd']}');
          lines.add('Valor R\$: R\$${item['valor_rs']}');
          lines.add('Suplementação: ${item['msg_suplementacao']}');
          lines.add('Situação: ${item['situacao']}');
          lines.add('OBS: ${item['obs_msg']}');
          if (i < results.length - 1) lines.add('---');
        }
        break;
      case SearchType.estoque:
        break;
    }
    return ResultCard(lines: lines);
  }

  @override
  Widget build(BuildContext context) {
    bool showAdvancedSearch = widget.searchType == SearchType.estoque;
    
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
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _performSearch(mode: StockSearchMode.exact),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[700],
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.black)) : Text(showAdvancedSearch ? 'Busca Exata' : 'Buscar'),
                ),
                if (showAdvancedSearch)
                  ElevatedButton(
                    onPressed: _isLoading ? null : () => _performSearch(mode: StockSearchMode.radical),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                    child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)) : const Text('Busca por Radical'),
                  ),
              ],
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
  final Color? backgroundColor;
  final Color? textColor;
  const ResultCard({super.key, required this.lines, this.backgroundColor, this.textColor});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: backgroundColor ?? Colors.black.withAlpha(178),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: lines.map((line) => Text(line, style: TextStyle(color: textColor ?? Colors.white, fontSize: 16, height: 1.5))).toList(),
        ),
      ),
    );
  }
}
