import { Component, OnInit, ViewChild, ViewContainerRef, ElementRef } from "@angular/core";
import * as app from "application";
import { NavigationEnd, Router } from "@angular/router";
import { Page } from "tns-core-modules/ui/page";
import { ModalDialogService, ModalDialogOptions } from "nativescript-angular/modal-dialog";

import { RouterExtensions } from "nativescript-angular/router";
import { DrawerTransitionBase, RadSideDrawer, SlideInOnTopTransition } from "nativescript-ui-sidedrawer";
import { RadListView, ListViewEventData } from "nativescript-ui-listview";
import { filter } from "rxjs/operators";

import { isIOS, isAndroid } from "platform";
declare var UIView, NSMutableArray, NSIndexPath;

import { LoginComponent } from './signin/signin.component';

import { HttpClient } from "@angular/common/http";
import { Observable } from "./rxjs-observable";
var localStorage = require("./nativescript-localstorage");

@Component({
    moduleId: module.id,
    providers: [ModalDialogService],
    selector: "ns-app",
    templateUrl: "app.component.html"
})
export class AppComponent implements OnInit {
    public items: any[];
    public user;
    private _activatedUrl: string;
    private _sideDrawerTransition: DrawerTransitionBase;

    constructor(private modalService: ModalDialogService, private viewContainerRef: ViewContainerRef, private page: Page, private router: Router, private routerExtensions: RouterExtensions, private http: HttpClient) {

    }

    public reload(): void {
        if (localStorage.getItem('sid') && localStorage.getItem('name')) {
            console.log("User is logged");
            this.user = {
                "code": localStorage.getItem('code'),
                "name": localStorage.getItem('name'),
                "username": localStorage.getItem('username')
            }            
            this.http.get('https://sysdev.studiocoder.com.br/menu?sid=' + localStorage.getItem('sid'))
                .subscribe((resp: any[]) => {
                    this.items = resp;
                    this.routerExtensions.navigate(["/home"]);
                }, (error: any[]) => {
                    if (error['status'] == 401) {
                        this.alert('Usuário ou senha incorretos');
                    } else {
                        this.alert(error['message']);
                    }
                    console.log('Erro: ', error);
                });
        } else {
            console.log("User don't logged");
            this.showModal();
        }
    }

    ngOnInit(): void {
        this._sideDrawerTransition = new SlideInOnTopTransition();

        this.router.events
            .pipe(filter((event: any) => event instanceof NavigationEnd))
            .subscribe((event: NavigationEnd) => this._activatedUrl = event.urlAfterRedirects);

        this.reload();
    }

    get sideDrawerTransition(): DrawerTransitionBase {
        return this._sideDrawerTransition;
    }

    isComponentSelected(url: string): boolean {
        return this._activatedUrl === url;
    }

    alert(message: string) {
        return alert({
            title: "sysDone",
            okButtonText: "OK",
            message: message
        });
    }

    templateSelector(item: any, index: number, items: any): string {
        return item.expanded ? "expanded" : "default";
    }

    showModal() {
        const options: ModalDialogOptions = {
            viewContainerRef: this.viewContainerRef,
            fullscreen: true,
            context: {}
        };
        this.modalService.showModal(LoginComponent, options)
            .then(resp => {
                this.reload();
            });
    }

    logout() {
        localStorage.removeItem('sid');
        localStorage.removeItem('usercode');
        localStorage.removeItem('name');
        localStorage.removeItem('username');
        this.showModal();
    }    

    onItemTap(event: ListViewEventData) {
        const listView = event.object,
            rowIndex = event.index,
            dataItem = event.view.bindingContext;

        dataItem.expanded = !dataItem.expanded;
        if (isIOS) {
            // Uncomment the lines below to avoid default animation
            // UIView.animateWithDurationAnimations(0, () => {
            var indexPaths = NSMutableArray.new();
            indexPaths.addObject(NSIndexPath.indexPathForRowInSection(rowIndex, event.groupIndex));
            listView.ios.reloadItemsAtIndexPaths(indexPaths);
            // });
        }
        if (isAndroid) {
            listView.androidListView.getAdapter().notifyItemChanged(rowIndex);
        }
        if (dataItem.action !== null) {
            this.onNavItemTap(dataItem.action);
        }
    }

    onSubitemTap(navItemRoute: string): void {
        this.onNavItemTap(navItemRoute);
    }

    onNavItemTap(navItemRoute: string): void {
        this.routerExtensions.navigate([navItemRoute], {
            transition: {
                name: "fade"
            }
        });

        const sideDrawer = <RadSideDrawer>app.getRootView();
        sideDrawer.closeDrawer();
    }
}
