import { Component, OnInit } from '@angular/core';
import { environment } from '../../../environments/environment';

@Component({
  selector: 'app-demo',
  templateUrl: './demo.html',
  styleUrls: ['./demo.scss']
})
export class DemoComponent implements OnInit {

  message = '';

  ngOnInit() {
    fetch(environment.apiUrl)
      .then(r => r.text())
      .then(t => this.message = t);
  }
}
