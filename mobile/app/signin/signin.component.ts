import { Component, ElementRef, ViewChild } from "@angular/core";
import * as app from "application";
import { ModalDialogParams } from "nativescript-angular/modal-dialog";
import { RouterExtensions } from "nativescript-angular/router";
import { RadSideDrawer } from "nativescript-ui-sidedrawer";
import { topmost } from "ui/frame";
import { Router } from "@angular/router";
import { alert, prompt } from "tns-core-modules/ui/dialogs";
import { Page } from "tns-core-modules/ui/page";

import { HttpClient } from "@angular/common/http";
import { Observable } from "../rxjs-observable";
var localStorage = require("../nativescript-localstorage");

@Component({
	selector: "app-login",
	moduleId: module.id,
	templateUrl: "./signin.component.html",
	styleUrls: ['./signin.component.css']
})
export class LoginComponent {
	processing = false;
	public input: any;
	public items: any[];
	@ViewChild("email") email: ElementRef;	
	@ViewChild("password") password: ElementRef;

	constructor(private params: ModalDialogParams, private page: Page, private routerExtensions: RouterExtensions, private router: Router, private http: HttpClient) {
		this.input = {
			"email": "",
			"password": ""
		}
	}

	submit() {
		if (!this.input.email || !this.input.password) {
			this.alert("Informe um usuário e senha");
			return;
		} else if (!this.input.email) {
			this.alert("Informe seu usuário");
			return;
		} else if (!this.input.password) {
			this.alert("Informe sua senha");
			return;
		}
		this.processing = true;
		this.login();
	}

	login() {
		var self = this;
		var param = JSON.stringify({
			'username': this.input.email,
			'password': this.input.password
		});

		this.http.post('https://sysdev.studiocoder.com.br/signin', param)
			.subscribe((data: any[]) => {
				self.processing = false;
				console.log('status: ', data['status']);
				if (data['status'] == 200) {
					localStorage.setItem('sid', data['sid']);
					data = data['user'];
					localStorage.setItem('code', data['code']);
					localStorage.setItem('name', data['name']);
					localStorage.setItem('username', data['username']);
					this.params.closeCallback();
				} else {
					self.alert(data['message']);
				}
			}, (error: any[]) => {
				self.processing = false;
				if (error['status'] == 401) {
					self.alert('Usuário ou senha incorretos');
				} else {
					self.alert(error['message']);
				}
				console.log('Erro: ', error)
			})
	}

	forgotPassword() {
		prompt({
			title: "Forgot Password",
			message: "Enter the email address you used to register for sysDone to reset your password.",
			inputType: "email",
			defaultText: "",
			okButtonText: "Ok",
			cancelButtonText: "Cancel"
		}).then((data) => {
			if (data.result) {
				this.alert("Unfortunately, an error occurred resetting your password.");
			}
		});
	}

	focusPassword() {
		this.password.nativeElement.focus();
	}

	resetPassword(email) {
		return true;
	}

	alert(message: string) {
		return alert({
			title: "sysDone",
			okButtonText: "OK",
			message: message
		});
	}

	onDrawerButtonTap(): void {
		const sideDrawer = <RadSideDrawer>app.getRootView();
		sideDrawer.showDrawer();
	}

}

