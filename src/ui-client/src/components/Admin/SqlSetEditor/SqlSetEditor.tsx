/* Copyright (c) 2019, UW Medicine Research IT, University of Washington
 * Developed by Nic Dobbins and Cliff Spital, CRIO Sean Mooney
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */ 

import React from 'react';
import { ConceptSqlSet, ConceptEvent } from '../../../models/admin/Concept';
import { Button, Container, Row, Col } from 'reactstrap';
import { setAdminConceptSqlSet, undoAdminSqlSetChanges, processApiUpdateQueue } from '../../../actions/admin/sqlSet';
import { conceptEditorValid } from '../../../utils/admin/concept';
import { SqlSetRow } from './SqlSetRow/SqlSetRow';
import { InformationModalState } from '../../../models/state/GeneralUiState';
import { showInfoModal } from '../../../actions/generalUi';
import AdminState, { AdminPanelPane } from '../../../models/state/AdminState';
import { checkIfAdminPanelUnsavedAndSetPane } from '../../../actions/admin/admin';
import { FiCornerUpLeft } from 'react-icons/fi';
import './SqlSetEditor.css';

interface Props {
    data: AdminState;
    dispatch: any;
}

export class SqlSetEditor extends React.PureComponent<Props> {
    private className = 'sqlset-editor';
    constructor(props: Props) {
        super(props);
    }

    public render() {
        const { data, dispatch } = this.props;
        const c = this.className;
        const evs: ConceptEvent[] = [ ...data.conceptEvents.events.values() ];
        
        return (
            <div className={`${c}-container`}>

                {/* Header */}
                <div className={`${c}-toprow`}>
                    <Button className='leaf-button leaf-button-addnew' onClick={this.handleAddSqlSetClick}>
                        + Create New SQL Set
                    </Button>
                    <Button className='leaf-button leaf-button-secondary' disabled={!data.sqlSets.changed} onClick={this.handleUndoChangesClick}>
                        Undo Changes
                    </Button>
                    <Button className='leaf-button leaf-button-primary' disabled={!data.sqlSets.changed} onClick={this.handleSaveChangesClick}>
                        Save
                    </Button>
                    <Button className='leaf-button leaf-button-primary back-to-editor' onClick={this.handleBackToConceptEditorClick}>
                        <FiCornerUpLeft /> 
                        Go to Concept Editor
                    </Button>
                </div>

                {/* Sets */}
                <div className={`${c}-table`}>
                    {[ ...data.sqlSets.sets.values() ]
                        .sort((a,b) => a.id > b.id ? -1 : 1)
                        .map((s) => <SqlSetRow set={s} dispatch={dispatch} key={s.id} state={data} eventTypes={evs}/>)
                    }
                </div>

            </div>
        );
    }

    private generateRandomIntegerId = () => {
        const { sets } = this.props.data.sqlSets;
        const max = Math.max.apply(Math, [ ...sets.values() ].map((s) => s.id));
        return max + 1;
    }

    /*
     * Create a new Concept SQL Set, updating 
     * the store and preparing a later API save event.
     */
    private handleAddSqlSetClick = () => {
        const { dispatch } = this.props;
        const newSet: ConceptSqlSet = {
            id: this.generateRandomIntegerId(),
            isEncounterBased: false,
            isEventBased: false,
            sqlFieldDate: '',
            sqlSetFrom: '',
            specializationGroups: new Map(),
            unsaved: true
        }
        dispatch(setAdminConceptSqlSet(newSet, true));
    }

    private handleUndoChangesClick = () => {
        const { dispatch } = this.props;
        dispatch(undoAdminSqlSetChanges());
    }

    private handleSaveChangesClick = () => {
        const { dispatch } = this.props;
        const valid = conceptEditorValid();
        if (valid) {
            dispatch(processApiUpdateQueue());
        } else {
            const info: InformationModalState = {
                body: "One or more validation errors were found, and are highlighted in red below. Please fill in data for these before saving changes.",
                header: "Validation Error",
                show: true
            };
            dispatch(showInfoModal(info));
        }
    }

    private handleBackToConceptEditorClick = () => {
        const { dispatch } = this.props;
        dispatch(checkIfAdminPanelUnsavedAndSetPane(AdminPanelPane.CONCEPTS));
    }
};
