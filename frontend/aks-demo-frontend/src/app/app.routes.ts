import { Routes } from '@angular/router';
import { HomeComponent } from './home/home';
import { DemoComponent } from './demo/demo/demo';

export const routes: Routes = [
  { path: '', component: HomeComponent },
  { path: 'demo', component: DemoComponent }
];
