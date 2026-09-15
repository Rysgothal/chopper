import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    const Color chart_2 = Color.fromARGB(92, 145, 145, 145);
    const Color backgroundchart = Color.fromARGB(255, 221, 221, 221);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 8, 8, 8),
      body: Column(
        children: [
          SizedBox(
            height: 220,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              child: Stack(
                clipBehavior: Clip.none, 
                children: [
                  Positioned.fill(
                    child: Container(color: backgroundchart),
                  ),
                  Positioned(
                    bottom: -30,
                    left: -30,
                    child: Icon(Icons.circle, size: 120, color: chart_2),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 24),
                        Container(
                          width: 100,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: chart_2,
                          ),
                          child: Center(
                            child: FaIcon(
                              FontAwesomeIcons.pills,
                              size: 40,
                              color: const Color.fromARGB(255, 5, 5, 5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Chopper',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            fontFamily: GoogleFonts.nunito().fontFamily,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  Positioned(
                    right: -75,
                    top: -75,
                    child: Icon(Icons.circle, size: 200, color: chart_2),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(width: 24),
              Text(
                'Bem-vindo',
                style: TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.w900,
                  fontFamily: GoogleFonts.nunito().fontFamily,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(width: 24),
              Expanded(
                child: Text(
                  'Gerenciador de remédios, seus remédios sempre em dia.',
                  style: TextStyle(
                    fontSize: 18,
                    color: const Color.fromARGB(123, 255, 255, 255),
                    fontWeight: FontWeight.w300,
                    fontFamily: GoogleFonts.nunito().fontFamily,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}