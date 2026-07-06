import 'package:flutter/material.dart';

void main() => runApp(MaterialApp(
  debugShowCheckedModeBanner: false,
  home: Home(),
));

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 120.0,
        backgroundColor: Colors.grey[200],
        title: Column(
          children: [
            Text(
              'John Smith',
              style: TextStyle(
                color: Colors.black,
                fontSize: 40.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            Divider(
              height: 20,
              thickness: 2,
              indent: 150,
              endIndent: 150,
              color: Colors.black,
            ),
            Text(
              'Front End Developer',
              style: TextStyle(
                fontSize: 20.0,
                color: Colors.black,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Body(),
    );
  }
}

class Body extends StatelessWidget {
  const Body({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10.0, 20.0, 30.0, 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EXPERIENCE',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                      letterSpacing: 2.0,
                    ),
                  ),
                  Divider(thickness: 2, color: Colors.black),
                  Text(
                    '\t Company Name',
                    style: TextStyle(color: Colors.grey[900], fontSize: 16.0,fontWeight: FontWeight.bold),
                  ),
                  Text(
                      '\t JOB TITLE/ROLE\n\nAddinitonal Information Here\n\n',
                      style :TextStyle(color: Colors.grey[500], fontSize: 13.0),),
                  Text(
                    '\t Company Name',
                    style: TextStyle(color: Colors.grey[900], fontSize: 16.0,fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '\t JOB TITLE/ROLE\n\nAddinitonal Information Here\n\n',
                    style :TextStyle(color: Colors.grey[500], fontSize: 13.0),),
                  Text(
                    '\t Company Name',
                    style: TextStyle(color: Colors.grey[900], fontSize: 16.0,fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '\t JOB TITLE/ROLE\n\nAddinitonal Information Here\n\n',
                    style :TextStyle(color: Colors.grey[500], fontSize: 13.0),),
                  SizedBox(height: 40.0),
                  Text(
                    'EDUCATION',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                      letterSpacing: 2.0,
                    ),
                  ),
                  Divider(thickness: 2, color: Colors.black),
                  Text(
                    '\t DEGREE/MAJOR',
                    style: TextStyle(color: Colors.grey[900], fontSize: 16.0,fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '\t COLLEGE OR UNIVERSITY\n\nAddinitonal Information Here\n\n',
                    style :TextStyle(color: Colors.grey[500], fontSize: 13.0),),
                ],
              ),
            ),
            VerticalDivider(
              width: 40,
              thickness: 2,
              color: Colors.black,
            ),
            // Right Column: Contact, Portfolio, Expertise
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CONTACT',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                      letterSpacing: 2.0,
                    ),
                  ),
                  Divider(thickness: 2, color: Colors.black),
                  Text(
                    '\n\t E-MAIL\n',
                    style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13.0,
                        fontWeight: FontWeight.bold
                    ),),
                  Text(
                    'john.smith@email.com\n',
                    style: TextStyle(color: Colors.grey[700], fontSize: 16.0),
                  ),
                  Text(
                    '\t PHONE NUMBER',
                    style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13.0,
                        fontWeight: FontWeight.bold
                    ),),
                  Text(
                    '\n+1 234 567 890',
                    style: TextStyle(color: Colors.grey[700], fontSize: 16.0),
                  ),
                  SizedBox(height: 30.0),
                  Text(
                    'PORTFOLIO',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                      letterSpacing: 2.0,
                    ),
                  ),
                  Divider(thickness: 2, color: Colors.black),
                  Text(
                    '\nwww.johnsmith.dev',
                    style: TextStyle(color: Colors.grey[700], fontSize: 16.0),
                  ),
                  SizedBox(height: 30.0),
                  Text(
                    'EXPERTISE',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                      letterSpacing: 2.0,
                    ),
                  ),
                  Divider(thickness: 2, color: Colors.black),
                  Text(
                    '\nFlutter & Dart\n\nUI/UX Design\n\nJavaScript & React',
                    style: TextStyle(color: Colors.grey[700], fontSize: 16.0),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
